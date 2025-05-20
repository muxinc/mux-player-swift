//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import AVFoundation
import Foundation
import os

// MARK: - FairPlayStreamingSessionManager

// Use AnyObject to restrict conformances only to reference
// types because the SDKs AVContentKeySessionDelegate holds
// a weak reference to the SDKs witness of this.
protocol FairPlayStreamingSessionCredentialClient: AnyObject {
    // MARK: Requesting licenses and certs

    // Requests the App Certificate for a playback id
    func requestCertificate(
        fromDomain rootDomain: String,
        playbackID: String,
        drmToken: String,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    )
    // Requests a license to play based on the given SPC data
    // - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String,
        offline _: Bool,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    )

    var logger: Logger { get set }
}

// MARK: - PlaybackOptionsRegistry

protocol PlaybackOptionsRegistry: AnyObject {
    /// Registers a ``PlaybackOptions`` for DRM playback, associated with the given playbackID
    func registerPlaybackOptions(_ opts: PlaybackOptions, for playbackID: String)
    /// Gets a DRM token previously registered via ``registerPlaybackOptions``
    func findRegisteredPlaybackOptions(for playbackID: String) -> PlaybackOptions?
    /// Unregisters a ``PlaybackOptions`` for DRM playback, given the assiciated playback ID
    func unregisterPlaybackOptions(for playbackID: String)
}

// MARK: - ContentKeyRecipientRegistry

// Intended for registering drm-protected AVURLAssets
protocol ContentKeyRecipientRegistry {
    /// Adds a ``AVContentKeyRecipient`` (probably an ``AVURLAsset``)  that must be played
    /// with DRM protection. This call is necessary for DRM playback to succeed
    func addContentKeyRecipient(_ recipient: AVContentKeyRecipient)
    /// Removes a ``AVContentKeyRecipient`` previously added by ``addContentKeyRecipient``
    func removeContentKeyRecipient(_ recipient: AVContentKeyRecipient)
}

// MARK: - FairPlayStreamingSessionManager

typealias FairPlayStreamingSessionManager = FairPlayStreamingSessionCredentialClient & PlaybackOptionsRegistry & ContentKeyRecipientRegistry

// MARK: - Content Key Provider

// Define protocol for calls made to AVContentKeySession
protocol ContentKeyProvider {
    func setDelegate(
        _ delegate: (any AVContentKeySessionDelegate)?,
        queue delegateQueue: dispatch_queue_t?
    )

    func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient)

    func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient)
}

// AVContentKeySession already has built-in definitions for
// these methods so this declaration can be empty
extension AVContentKeySession: ContentKeyProvider { }

// MARK: - DefaultFairPlayStreamingSessionManager

class DefaultFairPlayStreamingSessionManager<
    ContentKeySession: ContentKeyProvider
>: FairPlayStreamingSessionManager {

    var playbackOptionsByPlaybackID: [String: PlaybackOptions] = [:]
    let contentKeySession: ContentKeySession
    let errorDispatcher: (any ErrorDispatcher)
    
    private var _logger: Logger?
    var logger: Logger {
        get {
            if let logger = _logger {
                logger
            } else {
                PlayerSDK.shared.contentKeyLogger
            }
        }
        set(logger) {
            _logger = logger
        }
    }

    var sessionDelegate: AVContentKeySessionDelegate? {
        didSet {
            contentKeySession.setDelegate(
                sessionDelegate,
                queue: DispatchQueue(
                    label: "com.mux.player.fairplay"
                )
            )
        }
    }

    private let urlSession: URLSession
    
    func addContentKeyRecipient(_ recipient: AVContentKeyRecipient) {
        contentKeySession.addContentKeyRecipient(recipient)
    }
    
    func removeContentKeyRecipient(_ recipient: AVContentKeyRecipient) {
        contentKeySession.removeContentKeyRecipient(recipient)
    }
    
    // MARK: Requesting licenses and certs
    
    /// Requests the App Certificate for a playback id
    func requestCertificate(
        fromDomain rootDomain: String,
        playbackID: String,
        drmToken: String,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URLComponents(
            playbackID: playbackID,
            drmToken: drmToken,
            applicationCertificateHostSuffix: rootDomain
        ).url else {
            logger.debug(
                "Invalid FairPlay certificate domain \(rootDomain, privacy: .auto(mask: .hash))"
            )
            let error = FairPlaySessionError.unexpected(
                message: "Invalid certificate domain"
            )
            requestCompletion(
                Result.failure(
                    error
                )
            )
            errorDispatcher.dispatchApplicationCertificateRequestError(
                error: error,
                playbackID: playbackID
            )
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        logger.debug(
            "Requesting application certificate from \(url, privacy: .auto(mask: .hash))"
        )

        let dataTask = urlSession.dataTask(with: request) { [requestCompletion] data, response, error in
            self.logger.debug(
                "Application certificate request completed"
            )

            var responseCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
                self.logger.debug(
                    "Application certificate response code: \(httpResponse.statusCode)"
                )
                self.logger.debug(
                    "Application certificate response headers: \(httpResponse.allHeaderFields, privacy: .auto(mask: .hash))"
                )
                if let data, let utfData = String(
                    data: data,
                    encoding: .utf8
                ) {
                    self.logger.debug(
                        "Application certificate error: \(utfData)"
                    )
                }

            }
            // error case: I/O failed
            if let error = error {
                self.logger.debug(
                    "Applicate certificate request failed with error: \(error.localizedDescription)"
                )
                let error = FairPlaySessionError.because(cause: error)
                requestCompletion(Result.failure(
                    error
                ))
                self.errorDispatcher.dispatchApplicationCertificateRequestError(
                    error: error,
                    playbackID: playbackID
                )
                return
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                self.logger.debug(
                    "Applicate certificate request failed with response code: \(String(describing: responseCode))"
                )
                let error = FairPlaySessionError.httpFailed(
                    responseStatusCode: responseCode ?? 0
                )
                requestCompletion(
                    Result.failure(
                        error
                    )
                )
                self.errorDispatcher.dispatchApplicationCertificateRequestError(
                    error: error,
                    playbackID: playbackID
                )
                return
            }
            // this edge case (200 with invalid data) is possible from our DRM vendor
            guard let data = data,
                  data.count > 0 else {
                let error = FairPlaySessionError.unexpected(
                    message: "No cert data with 200 OK response"
                )
                self.logger.debug(
                    "Applicate certificate request completed with missing data and response code \(responseCode.debugDescription)"
                )
                requestCompletion(
                    Result.failure(
                        error
                    )
                )
                self.errorDispatcher.dispatchApplicationCertificateRequestError(
                    error: error,
                    playbackID: playbackID
                )
                return
            }
            
            self.logger.debug("Application certificate response data:\(data.base64EncodedString(), privacy: .auto(mask: .hash))")

            requestCompletion(Result.success(data))
        }
        
        dataTask.resume()
    }
    
    /// Requests a license to play based on the given SPC data
    /// - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String,
        offline _: Bool,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URLComponents(
            playbackID: playbackID,
            drmToken: drmToken,
            licenseHostSuffix: rootDomain
        ).url else {
            let error = FairPlaySessionError.unexpected(
                message: "Invalid FairPlay license domain"
            )
            requestCompletion(
                Result.failure(
                    error
                )
            )
            errorDispatcher.dispatchLicenseRequestError(
                error: error,
                playbackID: playbackID
            )
            return
        }

        var request = URLRequest(url: url)
        
        // POST body is the SPC bytes
        request.httpMethod = "POST"
        request.httpBody = spcData
        
        // QUERY PARAMS
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(String(format: "%lu", request.httpBody?.count ?? 0), forHTTPHeaderField: "Content-Length")
        logger.debug("Sending License/CKC Request to: \(request.url?.absoluteString ?? "nil")")
        logger.debug("\t with header fields: \(String(describing: request.allHTTPHeaderFields))")

        let task = urlSession.dataTask(with: request) { [requestCompletion] data, response, error in
            // error case: I/O failed
            if let error = error {
                self.logger.debug(
                    "URL Session Task Failed: \(error.localizedDescription)"
                )
                let error = FairPlaySessionError.because(cause: error)
                requestCompletion(Result.failure(
                    error
                ))
                self.errorDispatcher.dispatchLicenseRequestError(
                    error: error,
                    playbackID: playbackID
                )
                return
            }
            
            var responseCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
                self.logger.debug(
                    "License response code: \(httpResponse.statusCode)"
                )
                self.logger.debug(
                    "License response headers: \(httpResponse.allHeaderFields, privacy: .auto(mask: .hash))"
                )
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                self.logger.debug(
                    "CKC request failed: \(String(describing: responseCode))"
                )
                let error = FairPlaySessionError.httpFailed(
                    responseStatusCode: responseCode ?? 0
                )
                requestCompletion(Result.failure(
                    error
                ))
                self.errorDispatcher.dispatchLicenseRequestError(
                    error: error,
                    playbackID: playbackID
                )

                return
            }
            // strange edge case: 200 with no response body
            //  this happened because of a client-side encoding difference causing an error
            //  with our drm vendor and probably shouldn't be reachable, but lets not crash
            guard let data = data,
                  data.count > 0
            else {
                let error = FairPlaySessionError.unexpected(message: "No license data with 200 response")
                self.logger.debug("No CKC data despite server returning success")
                requestCompletion(Result.failure(
                    error
                ))
                self.errorDispatcher.dispatchLicenseRequestError(
                    error: error,
                    playbackID: playbackID
                )
                return
            }
            
            let ckcData = data
            requestCompletion(Result.success(ckcData))
        }
        task.resume()
    }
    
    // MARK: registering assets
    
    /// Registers a ``PlaybackOptions`` for DRM playback, associated with the given playbackID
    func registerPlaybackOptions(
        _ options: PlaybackOptions,
        for playbackID: String
    ) {
        logger.debug("Registering playbackID \(playbackID)")
        playbackOptionsByPlaybackID[playbackID] = options
    }
    
    /// Gets a DRM token previously registered via ``registerPlaybackOptions``
    func findRegisteredPlaybackOptions(
        for playbackID: String
    ) -> PlaybackOptions? {
        logger.debug("Finding playbackID \(playbackID)")
        return playbackOptionsByPlaybackID[playbackID]
    }
    
    /// Unregisters a ``PlaybackOptions`` for DRM playback, given the assiciated playback ID
    func unregisterPlaybackOptions(for playbackID: String) {
        logger.debug("UN-Registering playbackID \(playbackID)")
        playbackOptionsByPlaybackID.removeValue(forKey: playbackID)
    }

    // MARK: initializers

    init(
        contentKeySession: ContentKeySession,
        urlSession: URLSession,
        errorDispatcher: any ErrorDispatcher
    ) {
        self.contentKeySession = contentKeySession
        self.urlSession = urlSession
        self.errorDispatcher = errorDispatcher
    }
}

// MARK: - FairPlaySessionError

enum FairPlaySessionError : Error {
    case because(cause: any Error)
    case httpFailed(responseStatusCode: Int)
    case unexpected(message: String)
}
