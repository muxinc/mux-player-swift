//
//  ContentKeySessionDelegate.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import AVFoundation
import Foundation
import os

class ContentKeySessionDelegate<SessionManager: FairPlayStreamingSessionCredentialClient> : NSObject, AVContentKeySessionDelegate {
    
    weak var sessionManager: SessionManager?

    var logger: Logger

    init(
        sessionManager: SessionManager
    ) {
        self.sessionManager = sessionManager
        self.logger = sessionManager.logger
    }
    
    // MARK: AVContentKeySessionDelegate implementation
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didProvide keyRequest: AVContentKeyRequest
    ) {
        handleContentKeyRequest(
            request: DefaultKeyRequest(wrapping: keyRequest)
        )
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest
    ) {
        handleContentKeyRequest(request: DefaultKeyRequest(wrapping: keyRequest))
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest
    ) {
        logger.debug(
            "CK Request Succeeded"
        )
    }
    
    func contentKeySession(
        _ session: AVContentKeySession, contentKeyRequest
        keyRequest: AVContentKeyRequest, didFailWithError
        err: any Error
    ) {
        logger.debug(
            "CK Request Failed Error Localized Description: \(err.localizedDescription)"
        )

        let error = err as NSError
        if let localizedFailureReason = error.localizedFailureReason {
            logger.debug(
                "CK Request Failed Error Localized Failure Reason: \(localizedFailureReason))"
            )
        }

        logger.debug(
            "CK Request Failed Error Code: \(error.code)"
        )

        logger.debug(
            "CK Request Failed Error User Info: \(error.userInfo)"
        )

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            logger.debug(
                "CK Request Failed Underlying Error Localized Description: \(underlyingError.localizedDescription)"
            )

            logger.debug(
                "CK Request Failed Underlying Error Code: \(underlyingError.code)"
            )
        }
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        shouldRetry keyRequest: AVContentKeyRequest,
        reason retryReason: AVContentKeyRequest.RetryReason
    ) -> Bool {
        logger.debug(
            "Retrying with reason: \(retryReason.rawValue)"
        )

        switch retryReason {
            /*
             Indicates that the content key request should be retried because the key response was not set soon enough either
             due the initial request/response was taking too long, or a lease was expiring in the meantime.
             */
        case .timedOut:
            return true

            /*
             Indicates that the content key request should be retried because a key response with expired lease was set on the
             previous content key request.
             */
        case .receivedResponseWithExpiredLease:
            return true

            /*
             Indicates that the content key request should be retried because an obsolete key response was set on the previous
             content key request.
             */
        case .receivedObsoleteContentKey:
            return true

        default:
            return false
        }
    }
    
    // MARK: Logic
    
    func parsePlaybackId(fromSkdLocation uri: URL) -> String? {
        // pull the playbackID out of the uri to the key
        guard let urlComponents = URLComponents(
            url: uri,
            resolvingAgainstBaseURL: false
        ) else {
            // not likely
            logger.debug("\(#function) Error: cannot parse key URL [\(uri)]")
            return nil
        }

        return urlComponents.findQueryValue(
            key: "playbackId"
        )
    }
    
    func handleContentKeyRequest(request: any KeyRequest) {
        logger.debug(
            "Called \(#function)"
        )

        guard let sessionManager = self.sessionManager else {
            // TODO: Should this also invoke `processContentKeyResponseError`?
            logger.debug("Missing session manager")
            return
        }

        // for hls, "the identifier must be an NSURL that matches a key URI in the Media Playlist." from the docs
        guard let requestIdentifierString = request.identifier as? String,
              let mediaPlaylistKeyURL = URL(string: requestIdentifierString),
              let utfEncodedRequestIdentifierString = requestIdentifierString.data(using: .utf8)
        else {
            // TODO: Should this also invoke `processContentKeyResponseError`?
            logger.debug(
                "CK request identifier not a valid key url."
            )
            return
        }

        guard let playbackID = parsePlaybackId(
            fromSkdLocation: mediaPlaylistKeyURL
        ) else {
            request.processContentKeyResponseError(
                FairPlaySessionError.unexpected(
                    message: "playbackID not present in key uri"
                )
            )
            logger.debug("\(#function) Error: key url SDK location missing playbackId [\(mediaPlaylistKeyURL.absoluteString)]")
            return
        }

        // get app cert
        sessionManager.requestCertificate(
            playbackID: playbackID,
            completion: { [weak self] result in
                guard let self else {
                    PlayerSDK.shared.diagnosticsLogger.debug(
                        "Content key request completed: missing session delegate"
                    )
                    return
                }

                let applicationCertificate: Data
                do {
                    applicationCertificate = try result.get()
                } catch {
                    request.processContentKeyResponseError(
                        error
                    )
                    return
                }

                handleApplicationCertificate(
                    applicationCertificate,
                    contentIdentifier: utfEncodedRequestIdentifierString,
                    playbackID: playbackID,
                    request: request)
            }
        )
    }

    func handleApplicationCertificate(
        _ applicationCertificate: Data,
        contentIdentifier utfEncodedRequestIdentifierString: Data,
        playbackID: String,
        request: any KeyRequest
    ) {
        // exchange app cert for SPC using KeyRequest to give to CDM
        request.makeStreamingContentKeyRequestData(
            forApp: applicationCertificate,
            contentIdentifier: utfEncodedRequestIdentifierString,
            options: [AVContentKeyRequestProtocolVersionsKey: [1]]
        ) { [weak self] spcData, error in
            guard let self = self else {
                PlayerSDK.shared.diagnosticsLogger.debug(
                    "Content key request completed: missing session delegate"
                )
                return
            }
            
            guard let spcData = spcData else {
                request.processContentKeyResponseError(
                    error ?? FairPlaySessionError.unexpected(message: "no SPC")
                )
                return
            }
            
            // exchange SPC for CKC
            handleSpcObtainedFromCDM(
                spcData: spcData,
                playbackID: playbackID,
                request: request
            )
        }
    }
    
    func handleSpcObtainedFromCDM(
        spcData: Data,
        playbackID: String,
        request: any KeyRequest
    ) {
        guard let sessionManager = self.sessionManager else {
            logger.debug("Missing Session Manager")
            return
        }
        
        sessionManager.requestLicense(
            spcData: spcData,
            playbackID: playbackID,
            offline: false
        ) { [weak self] result in
            guard let self else {
                return
            }

            let ckcData: Data
            do {
                ckcData = try result.get()
            } catch {
                request.processContentKeyResponseError(
                    error
                )
                return
            }

            logger.debug("Submitting CKC to system")
            // Send CKC to CDM/wherever else so we can finally play our content
            let keyResponse = request.makeContentKeyResponse(
                data: ckcData
            )
            request.processContentKeyResponse(
                keyResponse
            )
            logger.debug("Protected content now available for processing")
            // Done! no further interaction is required from us to play.
        }
    }
}

// Wraps a generic request for a key and delegates calls to it
//  this protocol's methods are intended to match AVContentKeyRequest
protocol KeyRequest {
    
    associatedtype InnerRequest
    
    var identifier: Any? { get }
    
    func makeContentKeyResponse(data: Data) -> AVContentKeyResponse
    
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
    
    func makeContentKeyResponse(data: Data) -> AVContentKeyResponse {
        return AVContentKeyResponse(fairPlayStreamingKeyResponseData: data)
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
