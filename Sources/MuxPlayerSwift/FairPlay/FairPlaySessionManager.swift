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
        playbackID: String,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    )
    // Requests a license to play based on the given SPC data
    // - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        offline _: Bool,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    )

    var logger: Logger { get set }
}

// Intended for registering drm-protected AVURLAssets
protocol DRMAssetRegistry {
    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String)
}

// MARK: - FairPlayStreamingSessionManager

typealias FairPlayStreamingSessionManager = FairPlayStreamingSessionCredentialClient & DRMAssetRegistry

// MARK: - Content Key Provider

// Define protocol for calls made to AVContentKeySession
protocol ContentKeyProvider {
    func setDelegate(
        _ delegate: (any AVContentKeySessionDelegate)?,
        queue delegateQueue: dispatch_queue_t?
    )

    func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient)

    func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient)

    func recreate() -> Self
}

extension AVContentKeySession: ContentKeyProvider {
    func recreate() -> Self {
        if let storageURL {
            return Self(keySystem: keySystem, storageDirectoryAt: storageURL)
        } else {
            return Self(keySystem: keySystem)
        }
    }
}

// MARK: - DefaultFairPlayStreamingSessionManager

class DefaultFairPlayStreamingSessionManager<
    ContentKeySession: ContentKeyProvider
>: FairPlayStreamingSessionManager {
    private let queue: DispatchQueue

    private var notificationObservers = [NSObjectProtocol]()

    private struct DRMConfig {
        let options: PlaybackOptions.DRMPlaybackOptions
        let rootDomain: String
    }
    /// should be accessed on `queue`
    private var configLookup: [String: DRMConfig] = [:]

    private var contentKeySession: ContentKeySession {
        willSet {
            contentKeySession.setDelegate(nil, queue: nil)
        }
        didSet {
            contentKeySession.setDelegate(sessionDelegate, queue: queue)
        }
    }

    let errorDispatcher: (any ErrorDispatcher)

    #if DEBUG
    var logger: Logger = Logger(
        OSLog(
            subsystem: "com.mux.player",
            category: "CK"
        )
    )
    #else
    var logger: Logger = Logger(
        OSLog.disabled
    )
    #endif

    var sessionDelegate: AVContentKeySessionDelegate? {
        didSet {
            contentKeySession.setDelegate(
                sessionDelegate,
                queue: queue
            )
        }
    }

    private let urlSession: URLSession
    
    // MARK: Requesting licenses and certs
    
    /// Requests the App Certificate for a playback id
    func requestCertificate(
        playbackID: String,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    ) {
        guard let config = configLookup[playbackID] else {
            logger.debug(
                "No registered DRM configuration for playbackID \(playbackID)."
            )
            requestCompletion(
                .failure(
                    FairPlaySessionError.unexpected(
                        message: "No registered DRM configuration for playbackID \(playbackID)"
                    )
                )
            )
            return
        }

        let rootDomain = config.rootDomain
        let drmToken = config.options.drmToken

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
                        "Application certificate data: \(utfData)"
                    )
                }

            }
            // error case: I/O failed
            if let error = error {
                self.logger.debug(
                    "Application certificate request failed with error: \(error.localizedDescription)"
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
                    "Application certificate request failed with response code: \(String(describing: responseCode))"
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
                    "Application certificate request completed with missing data and response code \(responseCode.debugDescription)"
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
        offline: Bool,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    ) {
        guard let config = configLookup[playbackID] else {
            logger.debug(
                "No registered DRM configuration for playbackID \(playbackID)."
            )
            requestCompletion(
                .failure(
                    FairPlaySessionError.unexpected(
                        message: "No registered DRM configuration for playbackID \(playbackID)"
                    )
                )
            )
            return
        }

        let drmToken = config.options.drmToken
        let rootDomain = config.rootDomain

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

    // may be called from anywhere, playback must be possible by the time this function exits
    func addDRMAsset(
        _ urlAsset: AVURLAsset,
        playbackID: String,
        options: PlaybackOptions.DRMPlaybackOptions,
        rootDomain: String
    ) {
        // contentKeySession delegate callbacks will eventually need this, submit before starting the flow
        queue.async { [weak self] in
            self?.configLookup[playbackID] = DRMConfig(
                options: options,
                rootDomain: rootDomain)
        }
        contentKeySession.addContentKeyRecipient(urlAsset)
    }

    // MARK: error recovery

    private func handleMediaServicesLost() {
        queue.async { [weak self] in
            self?.configLookup.removeAll()
        }
        contentKeySession = contentKeySession.recreate()
    }

    // MARK: initializers

    init(
        contentKeySession: ContentKeySession,
        errorDispatcher: any ErrorDispatcher,
        urlSessionConfiguration baseURLSessionConfig: URLSessionConfiguration = .default,
        targetQueue: DispatchQueue = .global(qos: .default)
    ) {
        self.contentKeySession = contentKeySession
        self.errorDispatcher = errorDispatcher

        queue = DispatchQueue(
            label: "com.mux.player.fairplay",
            qos: .userInitiated,
            autoreleaseFrequency: .workItem,
            target: targetQueue)

        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        operationQueue.qualityOfService = .userInitiated

        let urlSessionConfiguration = baseURLSessionConfig.copy() as! URLSessionConfiguration
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.networkServiceType = .responsiveData

        urlSession = URLSession(
            configuration: urlSessionConfiguration,
            delegate: nil,
            delegateQueue: operationQueue)

        notificationObservers.append(
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.mediaServicesWereLostNotification,
                object: nil,
                queue: nil) { [weak self] _ in
                    self?.handleMediaServicesLost()
                }
        )
    }
}

// MARK: - FairPlaySessionError

enum FairPlaySessionError : Error {
    case because(cause: any Error)
    case httpFailed(responseStatusCode: Int)
    case unexpected(message: String)
}
