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
    
    func requestCertificate(playbackID: String) async throws -> Data
    
    func requestLicence(spcData: Data, playbackID: String) async throws -> Data

    var logger: Logger { get set }
}

// Intended for registering drm-protected AVURLAssets
protocol DRMAssetRegistry {
    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String)

    func addOfflineDownloadDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String)
    func removeOfflineDownloadSession(playbackID: String)
    func addOfflinePlayDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, keyData: Data) async
    func hasOfflineDRMConfig(playbackID: String) -> Bool
    func offlineKeyData(playbackID: String) -> Data?
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
    /// should be accessed on `queue`. Used for the online drm key-fetching flow
    private var onlineKeyConfigLookup: [String: DRMConfig] = [:]
    /// should be accessed on `queue`. Used for the offline-download key-fetching flow
    private var offlineDownloadKeyLookup: [String: DRMConfig] = [:]
    /// should be accessed on `queue`. Used for the offline-download key-fetching flow
    private var offlinePlayLookup: [String: Data] = [:]
    /// should be accessed on `queue`. Per-download content key sessions,
    /// keyed by playbackID. Each download gets its own session so
    /// re-downloads can trigger a fresh key request flow.
    private var downloadKeySessions: [String: ContentKeySession] = [:]
    /// should be accessed on `queue`. Delegates for per-download sessions.
    /// Stored to prevent deallocation since AVContentKeySession holds a
    /// weak reference to its delegate.
    private var downloadKeyDelegates: [String: AVContentKeySessionDelegate] = [:]

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
    
    private func offlineDRMConfigOnQueue(for playbackID: String) async -> DRMConfig? {
        return await withCheckedContinuation { continuation in
            queue.async { [offlineDownloadKeyLookup] in
                continuation.resume(returning: offlineDownloadKeyLookup[playbackID])
            }
        }
    }
    
    // MARK: Requesting licenses and certs
    
    func requestCertificate(playbackID: String) async throws -> Data {
        guard let config = await offlineDRMConfigOnQueue(for: playbackID) else {
            throw FairPlaySessionError.unexpected(message: "No DRM config tracked for playbackID: \(playbackID)")
        }
        
        // TODO: (future maintenance) request should be async by default, not completion handlers by default
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing:
                    FairPlaySessionError.unexpected(message: "SessionManager terminated while fetching app cert")
                )
                return
            }
            
            self.requestCertificateInner(playbackID: playbackID, drmConfig: config) { continuation.resume(with: $0) }
        }
    }
    
    func requestLicence(spcData: Data, playbackID: String) async throws -> Data {
        guard let config = await offlineDRMConfigOnQueue(for: playbackID) else {
            throw FairPlaySessionError.unexpected(message: "No DRM config tracked for playbackID: \(playbackID)")
        }
        
        // TODO: (future maintenance) request should be async by default, not completion handlers by default
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing:
                    FairPlaySessionError.unexpected(message: "SessionManager terminated while fetching license")
                )
                return
            }
            
            self.requestLicenseInner(
                spcData: spcData,
                playbackID: playbackID,
                drmConfig: config
            ) { continuation.resume(with: $0) }
        }
    }
    
    func requestCertificate(
        playbackID: String,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    ) {
        guard let config = onlineKeyConfigLookup[playbackID] else {
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
        
        requestCertificateInner(playbackID: playbackID, drmConfig: config, completion: requestCompletion)
    }

    func requestLicense(
        spcData: Data,
        playbackID: String,
        offline: Bool,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    ) {
        guard let config = onlineKeyConfigLookup[playbackID] else {
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
        
        requestLicenseInner(spcData: spcData, playbackID: playbackID, drmConfig: config, completion: requestCompletion)
    }
    
    /// Requests the App Certificate for a playback id
    private func requestCertificateInner(
        playbackID: String,
        drmConfig config: DRMConfig,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    ) {
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
    private func requestLicenseInner(
        spcData: Data,
        playbackID: String,
        drmConfig config: DRMConfig,
        completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void
    ) {

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
            self?.onlineKeyConfigLookup[playbackID] = DRMConfig(
                options: options,
                rootDomain: rootDomain)
        }
        contentKeySession.addContentKeyRecipient(urlAsset)
    }
    
    func addOfflineDownloadDRMAsset(
        _ urlAsset: AVURLAsset,
        playbackID: String,
        options: PlaybackOptions.DRMPlaybackOptions,
        rootDomain: String
    ) {
        // Create a fresh session for this download so re-downloads
        // always trigger a new key request flow
        let downloadSession = contentKeySession.recreate()
        let delegate = ContentKeySessionDelegate(sessionManager: self)
        downloadSession.setDelegate(delegate, queue: queue)
        queue.async { [weak self] in
            self?.offlineDownloadKeyLookup[playbackID] = DRMConfig(
                options: options,
                rootDomain: rootDomain
            )
            self?.downloadKeySessions[playbackID] = downloadSession
            self?.downloadKeyDelegates[playbackID] = delegate
        }
        downloadSession.addContentKeyRecipient(urlAsset)
    }

    func removeOfflineDownloadSession(playbackID: String) {
        queue.async { [weak self] in
            self?.downloadKeySessions[playbackID]?.setDelegate(nil, queue: nil)
            self?.downloadKeySessions[playbackID] = nil
            self?.downloadKeyDelegates[playbackID] = nil
            self?.offlineDownloadKeyLookup[playbackID] = nil
        }
    }
    
    func addOfflinePlayDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, keyData: Data) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                self?.offlinePlayLookup[playbackID] = keyData
                continuation.resume()
            }
        }
        self.contentKeySession.addContentKeyRecipient(urlAsset)
    }
    
    func hasOfflineDRMConfig(playbackID: String) -> Bool {
        // called from ContentKeySessionDelegate, is definitely on .queue
        return offlinePlayLookup[playbackID] != nil || offlineDownloadKeyLookup[playbackID] != nil
    }
    
    func offlineKeyData(playbackID: String) -> Data? {
        return offlinePlayLookup[playbackID]
    }

    // MARK: error recovery

    private func handleMediaServicesLost() {
        queue.async { [weak self] in
            guard let self else { return }
            self.onlineKeyConfigLookup.removeAll()
            self.offlinePlayLookup.removeAll()
            self.offlineDownloadKeyLookup.removeAll()
            for (_, session) in self.downloadKeySessions {
                session.setDelegate(nil, queue: nil)
            }
            self.downloadKeySessions.removeAll()
            self.downloadKeyDelegates.removeAll()
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
