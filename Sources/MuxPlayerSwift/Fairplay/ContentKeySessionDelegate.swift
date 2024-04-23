//
//  ContentKeySessionDelegate.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

class ContentKeySessionDelegate : NSObject, AVContentKeySessionDelegate {
    
    // MARK: AVContentKeySessionDelegate implementation
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        handleContentKeyRequest(session, request: keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        handleContentKeyRequest(session, request: keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest,
                           reason retryReason: AVContentKeyRequest.RetryReason) -> Bool {
        
        var shouldRetry = false
        
        switch retryReason {
            /*
             Indicates that the content key request should be retried because the key response was not set soon enough either
             due the initial request/response was taking too long, or a lease was expiring in the meantime.
             */
        case AVContentKeyRequest.RetryReason.timedOut:
            shouldRetry = true
            
            /*
             Indicates that the content key request should be retried because a key response with expired lease was set on the
             previous content key request.
             */
        case AVContentKeyRequest.RetryReason.receivedResponseWithExpiredLease:
            shouldRetry = true
            
            /*
             Indicates that the content key request should be retried because an obsolete key response was set on the previous
             content key request.
             */
        case AVContentKeyRequest.RetryReason.receivedObsoleteContentKey:
            shouldRetry = true
            
        default:
            break
        }
        
        return shouldRetry
    }
    
    // MARK: Logic
    
    private func handleContentKeyRequest(_ session: AVContentKeySession, request: AVContentKeyRequest) {
        // for hls, "the identifier must be an NSURL that matches a key URI in the Media Playlist." from the docs
        guard let keyURLStr = request.identifier as? String,
              let keyURL = URL(string: keyURLStr),
              let assetIDData = keyURLStr.data(using: .utf8)
        else {
            print("request identifier was not a key url, this is exceptional for hls")
            return
        }
        
        // get app cert
        var applicationCertificate: Data?
        //  the drmtoday example does this by joining a dispatch group, but is this best?
        let group = DispatchGroup()
        group.enter()
        FairplaySessionManager.shared.requestCertificate(
            playbackID: "", // todo - get from sdk caller
            drmToken: "", // todo - get from sdk caller
            completion: { result in
                if let cert = try? result.get() {
                    applicationCertificate = cert
                }
                group.leave()
            }
        )
        group.wait()
        guard let applicationCertificate = applicationCertificate else {
            print("failed to get application certificate")
            return
        }
        
        // step: exchange app cert for SPC using KeyRequest w/completion handler (request wants to know if failed)
        request.makeStreamingContentKeyRequestData(forApp: applicationCertificate,
                                                   contentIdentifier: assetIDData,
                                                   options: [AVContentKeyRequestProtocolVersionsKey: [1]]) { [weak self] spcData, error in
            guard let self = self else {
                // todo - log or something?
                return
            }
            
            guard let spcData = spcData else {
                print("No SPC Data in spc response")
                // `error` will be non-nil by contract
                request.processContentKeyResponseError(error!)
                return
            }
            // step: exchange SPC for CKC using KeyRequest w/completion handler (request wants to know if failed)
            // todo - drmToken from Asset
            handleContentKeyResponse(spcData: spcData, drmToken: "", request: request)
        }
    }
    
    private func handleContentKeyResponse(spcData: Data, drmToken: String, request: AVContentKeyRequest)  {
        // Send SPC to Key Server and obtain CKC
        let asset: AVURLAsset // todo - obtain from sdk caller
        let playbackID: String = "" // todo - obtain from sdk caller / url of asset
        
        // todo - DRM Today example does this by joining a DispatchGroup. Is this acutally preferable
        var ckcData: Data? = nil
        let group = DispatchGroup()
        group.enter()
        FairplaySessionManager.shared.requestLicense(spcData: spcData, playbackID: playbackID, drmToken: drmToken, offline: false) { result in
            if let data = try? result.get() {
                ckcData = data
            }
            group.leave()
        }
        group.wait()
        
        guard let ckcData = ckcData else {
            print("no CKC Data in CKC response")
            return
        }
        
        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
        
        request.processContentKeyResponse(keyResponse)
    }
}
