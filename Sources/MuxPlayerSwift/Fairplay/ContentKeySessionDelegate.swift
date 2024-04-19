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
        
        // step: get app cert (ContentKeyRequest wants to know if this failed)
        //  the drmtoday example does this synchronously with DispatchGroups, but do we really need to do that?
        var applicationCertificate: Data?
        let group = DispatchGroup()
        FairplaySessionManager.shared.requestCertificate(
            playbackID: "", // todo - get through-line from api
            drmKey: "", // todo - get through-line from api
            completion: { result in
                if let cert = try? result.get() {
                    applicationCertificate = cert
                }
                    
            }
        )
        
        request.makeStreamingContentKeyRequestData(forApp: applicationCertificate,
                                                      contentIdentifier: assetIDData,
                                                      options: [AVContentKeyRequestProtocolVersionsKey: [1]],
                                                      completionHandler: completionHandler)
        
        // step: exchange app cert for SPC using KeyRequest w/completion handler
        
        // step: exchange SPC for CKC using KeyRequest w/completion handler
    }
    
    private func
}
