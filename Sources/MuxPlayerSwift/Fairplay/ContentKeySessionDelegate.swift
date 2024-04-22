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
        // "the identifier must be an NSURL that matches a key URI in the Media Playlist." from the docs
        guard let keyURLStr = request.identifier as? String,
              let keyURL = URL(string: keyURLStr),
              let assetIDData = keyURLStr.data(using: .utf8)
        else {
            print("request identifier was not a key url, this is exceptional for hls")
            return
        }
        
        // get app cert
        var applicationCertificate: Data?
        //  the drmtoday example does this synchronously with DispatchGroups, but do we really need to do that?
        let group = DispatchGroup()
        group.enter()
        FairplaySessionManager.shared.requestCertificate(
            playbackID: "", // todo - get from sdk caller
            drmKey: "", // todo - get from sdk caller
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
                print("SPC request failed")
                // `error` will be non-nil by contract
                request.processContentKeyResponseError(error!)
                return
            }
            do {
                // step: exchange SPC for CKC using KeyRequest w/completion handler (request wants to know if failed)
                try handleContentKeyResponse(spcData: spcData, request: request)
            } catch {
                request.processContentKeyResponseError(error)
            }
        }
    }
    
    private func handleContentKeyResponse(spcData: Data, request: AVContentKeyRequest)  {
        do {
            // Send SPC to Key Server and obtain CKC
            let asset: AVURLAsset // todo - obtain from sdk caller
            let playbackID: String // todo - obtain from sdk caller / url of asset
            
            // todo - DRM Today example does this synchronously with DispatchGroup. Is that really necessary?
            let ckcData = try requestContentKeyFromKeySecurityModule(nil, spcData: spcData, playbackID: playbackID, persistable: false)
            
            /*
             AVContentKeyResponse is used to represent the data returned from the key server when requesting a key for
             decrypting content.
             */
            let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
            
            /*
             Provide the content key response to make protected content available for processing.
             */
            request.processContentKeyResponse(keyResponse)
        } catch {
            request.processContentKeyResponseError(error)
        }
    }
    
    func requestContentKeyFromKeySecurityModule(_ asset: AVURLAsset?, spcData: Data, playbackID: String, persistable: Bool) throws -> Data {
        
        // MARK: ADAPT - You must implement this method to request a CKC from your KSM.
        
        guard let asset = asset else {
                    return Data()
                }
        
        var ckcData: Data? = nil
                
        let data = try JSONEncoder().encode(asset.stream)
        let stream = try JSONDecoder().decode(Stream.self, from: data)
        let token : String? = nil // "{authToken}"
        
        let group = DispatchGroup()
        group.enter()
        DRMtoday.getLicense(stream: stream, spcData: spcData, token: token, offline: persistable) { (ckc) in
            ckcData = ckc
            let escapedName = asset.stream.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let filename = self.getDocumentsDirectory().appendingPathComponent("").appendingPathComponent(escapedName! + (persistable ? "offline" : "online") + ".dat")
            do {
                try ckcData?.write(to: filename, options: .atomicWrite)
            } catch {
                print("Unable to write a license file")
            }
            group.leave()
        }
        group.wait()
        
        guard ckcData != nil else {
            throw ProgramError.noCKCReturnedByKSM
        }
        
        return ckcData!
    }
}
