//
//  ContentKeySessionDelegate.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

class ContentKeySessionDelegate<SessionManager: FairPlayStreamingSessionCredentialClient & PlaybackOptionsRegistry> : NSObject, AVContentKeySessionDelegate {
    
    weak var credentialClient: FairPlayStreamingSessionCredentialClient?
    weak var playbackOptionsRegistry: PlaybackOptionsRegistry?

    convenience init(
        sessionManager: SessionManager
    ) {
        self.init(
            credentialClient: sessionManager,
            optionsRegistry: sessionManager
        )
    }
    
    init (
        credentialClient: FairPlayStreamingSessionCredentialClient,
        optionsRegistry: PlaybackOptionsRegistry
    ) {
        self.credentialClient = credentialClient
        self.playbackOptionsRegistry = optionsRegistry
    }
    
    // MARK: AVContentKeySessionDelegate implementation
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        handleContentKeyRequest(request: DefaultKeyRequest(wrapping: keyRequest))
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        handleContentKeyRequest(request: DefaultKeyRequest(wrapping: keyRequest))
    }
    
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest) {
        // this func intentionally left blank
        // TODO: Log more nicely (ie, with a Logger)
        print("CKC Request Success")
    }
    
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: any Error) {
        // TODO: Log more nicely (ie, with a Logger)
        print("CKC Request Failed!!! \(err.localizedDescription)")
    }
    
    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest,
                           reason retryReason: AVContentKeyRequest.RetryReason) -> Bool {
        // TODO: use Logger
        print("shouldRetry called with reason \(retryReason)")
        
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
    
    func handleContentKeyRequest(request: any KeyRequest) {
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
            request.processContentKeyResponseError(
                FairPlaySessionError.unexpected(
                    message: "playbackID not present in key uri"
                )
            )
            return
        }
        
        guard let credentialClient = self.credentialClient  else {
            return
        }
        
        guard let optionsRegistry = self.playbackOptionsRegistry  else {
            return
        }

        let playbackOptions = optionsRegistry.findRegisteredPlaybackOptions(
            for: playbackID
        )
        guard let playbackOptions = playbackOptions,
              case .drm(let drmOptions) = playbackOptions.playbackPolicy else {
            print("DRM Tokens must be registered when the AVPlayerItem is created, using FairplaySessionManager")
            request.processContentKeyResponseError(
                FairPlaySessionError.unexpected(
                    message: "Token was not registered, only happens during SDK errors"
                )
            )
            return
        }
        
        let rootDomain = playbackOptions.rootDomain()
        
        // get app cert
        var applicationCertificate: Data?
        var appCertError: (any Error)?
        //  the drmtoday example does this by joining a dispatch group, but is this best?
        let group = DispatchGroup()
        group.enter()
        credentialClient.requestCertificate(
            fromDomain: rootDomain,
            playbackID: playbackID,
            drmToken: drmOptions.drmToken,
            completion: { result in
                do {
                    applicationCertificate = try result.get()
                } catch {
                    appCertError = error
                }
                group.leave()
            }
        )
        group.wait()
        guard let applicationCertificate = applicationCertificate else {
            request.processContentKeyResponseError(
                FairPlaySessionError.because(
                    cause: appCertError!
                )
            )
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
    
    func handleSpcObtainedFromCDM(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String, // without any "license." or "stream." prepended, eg mux.com, custom.1234.co.uk
        request: any KeyRequest
    ) {
        guard let credendtialClient = self.credentialClient else {
            print("Missing Session Manager")
            return
        }
        
//        guard let optionsRegistry = self.playbackOptionsRegistry else {
//            print("Missing Session Manager")
//            return
//        }

        // todo - DRM Today example does this by joining a DispatchGroup. Is this really preferable??
        var ckcData: Data? = nil
        let group = DispatchGroup()
        group.enter()
        credendtialClient.requestLicense(
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

// Wraps a generic request for a key and delegates calls to it
//  this protocol's methods are intended to match AVContentKeyRequest
protocol KeyRequest {
    
    associatedtype InnerRequest
    
    var identifier: Any? { get }
    
    func processContentKeyResponse(_ response: AVContentKeyResponse)
    func processContentKeyResponseError(_ error: any Error)
    func makeStreamingContentKeyRequestData(forApp appIdentifier: Data,
                                            contentIdentifier: Data?,
                                            options: [String : Any]?,
                                            completionHandler handler: @escaping (Data?, (any Error)?) -> Void)
}

// Wraps a real AVContentKeyRequest and straightforwardly delegates to it
struct DefaultKeyRequest : KeyRequest {
    typealias InnerRequest = AVContentKeyRequest
    
    var identifier: Any? {
        get {
            return self.request.identifier
        }
    }
    
    func processContentKeyResponse(_ response: AVContentKeyResponse) {
        self.request.processContentKeyResponse(response)
    }
    
    func processContentKeyResponseError(_ error: any Error) {
        self.request.processContentKeyResponseError(error)
    }
    
    func makeStreamingContentKeyRequestData(
        forApp appIdentifier: Data,
        contentIdentifier: Data?,
        options: [String : Any]? = nil,
        completionHandler handler: @escaping (Data?, (any Error)?) -> Void
    ) {
        self.request.makeStreamingContentKeyRequestData(
            forApp: appIdentifier,
            contentIdentifier: contentIdentifier,
            options: options,
            completionHandler: handler
        )
    }
    
    let request: InnerRequest
    
    init(wrapping request: InnerRequest) {
        self.request = request
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
