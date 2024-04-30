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
    
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest) {
        // this func intentionally left blank
        print("CKC Request Success")
    }
    
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: any Error) {
        print("CKC Request Failed!!! \(err.localizedDescription)")
    }
    
    func contentKeySessionContentProtectionSessionIdentifierDidChange(_ session: AVContentKeySession) {
        print("Content Key session ID changed apparently")
    }
    
    func contentKeySessionDidGenerateExpiredSessionReport(_ session: AVContentKeySession) {
        print("Expired session report generated (whatever that means)")
    }
    
    func contentKeySession(_ session: AVContentKeySession, externalProtectionStatusDidChangeFor contentKey: AVContentKey) {
        print("External Protection status changed for a content key sesison")
    }
    
    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest,
                           reason retryReason: AVContentKeyRequest.RetryReason) -> Bool {
        print("===shouldRetry called with reason \(retryReason)")
        
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
    
    private func lookUpDRMOptions(bySKDKeyUri uri: URL) -> (String, PlaybackOptions.DRMPlaybackOptions)? {
        // TODO: We need to be able to look up our DRM Key & Playback ID here.
        //  DRMToday example uses keyURLStr, but not known if we can do the same
        //  The keyURL is provided by the delivery infra, and our implementation would
        //  need to have the playback ID in the key URL for this same thing to work
        
        let urlComponents = URLComponents(url: uri, resolvingAgainstBaseURL: false)
        guard let urlComponents = urlComponents else {
            // not likely
            print("!! Error: Cannot Parse URI")
            return nil
        }
        
        let playbackID = urlComponents.findQueryValue(key: "playbackId")
        guard let playbackID = playbackID else {
            print("!! Error: URI [\(uri)] did not have playbackId!")
            return nil
        }
        print("|| PlaybackID from \(uri) is \(playbackID)")
        
        let playbackOptions = PlayerSDK.shared.fairplaySessionManager
            .findRegisteredPlaybackOptions(for: playbackID)
        if let playbackOptions = playbackOptions,
           case .drm(let drmOptions) = playbackOptions.playbackPolicy
        {
            print("Found DRMPlaybackOptions for \(playbackID)")
            return (playbackID, drmOptions)
        } else {
            print("Found NO playback options for \(playbackID)")
            return nil
        }
    }
    
    private func handleContentKeyRequest(_ session: AVContentKeySession, request: AVContentKeyRequest) {
        print("<><>handleContentKeyRequest: Called")
        // for hls, "the identifier must be an NSURL that matches a key URI in the Media Playlist." from the docs
        guard let keyURLStr = request.identifier as? String,
              let keyURL = URL(string: keyURLStr),
              let assetIDData = keyURLStr.data(using: .utf8)
        else {
            print("request identifier was not a key url, this is exceptional for hls")
            return
        }
        
        guard let (playbackID, drmOptions) = lookUpDRMOptions(bySKDKeyUri: keyURL) else {
            print("DRM Tokens must be registered when the AVPlayerItem is created, using FairplaySessionManager")
            return
        }
        
        // get app cert
        var applicationCertificate: Data?
        //  the drmtoday example does this by joining a dispatch group, but is this best?
        let group = DispatchGroup()
        group.enter()
        PlayerSDK.shared.fairplaySessionManager.requestCertificate(
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
        print("CERTIFICATE :: Giving App Cert to CDM: \(applicationCertificate?.base64EncodedString())")
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
            handleContentKeyResponse(spcData: spcData, playbackID: playbackID, drmToken: drmOptions.drmToken, domain: "TODO - Not Hooked Up!", request: request)
        }
    }
    
    private func handleContentKeyResponse(spcData: Data, playbackID: String, drmToken: String, domain: String, request: AVContentKeyRequest)  {
        // Send SPC to Key Server and obtain CKC
//        let playbackID: String = playbackID // todo - obtain from sdk caller / url of asset
        
        // todo - DRM Today example does this by joining a DispatchGroup. Is this really preferable??
        var ckcData: Data? = nil
        let group = DispatchGroup()
        group.enter()
        PlayerSDK.shared.fairplaySessionManager.requestLicense(spcData: spcData, playbackID: playbackID, drmToken: drmToken, playbackDomain: domain, offline: false) { result in
            if let data = try? result.get() {
                ckcData = data
            }
            group.leave()
        }
        group.wait()
        
        // TODO - On error, CKC request returns a body so we can't rely on this
        guard let ckcData = ckcData else {
            print("no CKC Data in CKC response")
            return
        }
        
        print("<><> Providing CKC to System!")
        // Send CKC to CDM/wherever else so we can finally play our content
        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
        request.processContentKeyResponse(keyResponse)
    }
}

extension URLComponents {
    func findQueryValue(key: String) -> String? {
        if let items = self.queryItems {
            for item in items {
                if item.name.lowercased() == key.lowercased() {
                    return item.value
                }
            }
        }
        
        return nil
    }
}
