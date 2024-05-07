//
//  ContentKeySessionDelegate.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

class ContentKeySessionDelegate<SessionManager: FairPlayStreamingSessionManager> : NSObject, AVContentKeySessionDelegate {

    weak var sessionManager: SessionManager?

    init(
        sessionManager: SessionManager
    ) {
        self.sessionManager = sessionManager
    }

    // MARK: AVContentKeySessionDelegate implementation
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        handleContentKeyRequest(request: keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        handleContentKeyRequest(request: keyRequest)
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
    
    func parsePlaybackId(fromSkdLocation uri: URL) -> String? {
       // pull the playbackID out of the uri to the key
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
        return playbackID
    }
    
    func handleContentKeyRequest(request: AVContentKeyRequest) {
        print("<><>handleContentKeyRequest: Called")
        // for hls, "the identifier must be an NSURL that matches a key URI in the Media Playlist." from the docs
        guard let keyURLStr = request.identifier as? String,
              let keyURL = URL(string: keyURLStr),
              let assetIDData = keyURLStr.data(using: .utf8)
        else {
            print("request identifier was not a key url, this is exceptional for hls")
            return
        }
        
        let playbackID = parsePlaybackId(fromSkdLocation: keyURL)
        guard let playbackID = playbackID else {
            print("No playbackID found from server , aborting")
            return
        }
        
        guard let sessionManager = self.sessionManager else {
            print("Missing Session Manager")
            return
        }

        let playbackOptions = sessionManager.findRegisteredPlaybackOptions(
            for: playbackID
        )
        guard let playbackOptions = playbackOptions,
              case .drm(let drmOptions) = playbackOptions.playbackPolicy else {
            print("DRM Tokens must be registered when the AVPlayerItem is created, using FairplaySessionManager")
            return
        }
        
        let rootDomain = playbackOptions.rootDomain()
        
        // get app cert
        var applicationCertificate: Data?
        //  the drmtoday example does this by joining a dispatch group, but is this best?
        let group = DispatchGroup()
        group.enter()
        sessionManager.requestCertificate(
            fromDomain: rootDomain,
            playbackID: playbackID,
            drmToken: drmOptions.drmToken,
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
        
        // exchange app cert for SPC using KeyRequest to give to CDM
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
            
            // exchange SPC for CKC
            handleSpcObtainedFromCDM(
                spcData: spcData,
                playbackID: playbackID,
                drmToken: drmOptions.drmToken,
                rootDomain: rootDomain,
                request: request
            )
        }
    }
    
    private func handleSpcObtainedFromCDM(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String, // without any "license." or "stream." prepended, eg mux.com, custom.1234.co.uk
        request: AVContentKeyRequest
    ) {
        guard let sessionManager = self.sessionManager else {
            print("Missing Session Manager")
            return
        }

        // todo - DRM Today example does this by joining a DispatchGroup. Is this really preferable??
        var ckcData: Data? = nil
        let group = DispatchGroup()
        group.enter()
        sessionManager.requestLicense(
            spcData: spcData,
            playbackID: playbackID,
            drmToken: drmToken,
            rootDomain: rootDomain,
            offline: false
        ) { result in
            if let data = try? result.get() {
                ckcData = data
            }
            group.leave()
        }
        group.wait()
        
        guard let ckcData = ckcData else {
            print("no CKC Data in CKC response")
            request.processContentKeyResponseError(FairPlaySessionError.unexpected(message: "No CKC Data returned from CDM"))
            return
        }
        
        print("Submitting CKC to system")
        // Send CKC to CDM/wherever else so we can finally play our content
        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
        request.processContentKeyResponse(keyResponse)
        // Done! no further interaction is required from us to play.
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
