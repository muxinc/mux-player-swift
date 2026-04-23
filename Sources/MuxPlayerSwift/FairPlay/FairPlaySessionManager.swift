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
    func requestCertificate(playbackID: String, online: Bool) async throws -> Data
    
    // Requests a license to play based on the given SPC data
    func requestLicense(spcData: Data, playbackID: String, online: Bool) async throws -> Data
    
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
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("looked up offline DRMConfig after cleanup")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: offlineDownloadKeyLookup[playbackID])
            }
        }
    }
    
    private func onlineDRMConfigOnQueue(for playbackID: String) async -> DRMConfig? {
        return await withCheckedContinuation { continuation in
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("looked up online DRMConfig after cleanup")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: onlineKeyConfigLookup[playbackID])
            }
        }
    }
    
    // MARK: Requesting licenses and certs
    
    func requestCertificate(playbackID: String, online: Bool) async throws -> Data {
        guard let config = await lookUpDRMConfig(playbackID: playbackID, online: online) else {
            throw FairPlaySessionError.unexpected(message: "No DRM config tracked for playbackID: \(playbackID)")
        }
        return try await self.requestCertificateInner(playbackID: playbackID, drmConfig: config)
    }
    
    func requestLicense(spcData: Data, playbackID: String, online: Bool) async throws -> Data {
        guard let config = await lookUpDRMConfig(playbackID: playbackID, online: online) else {
            throw FairPlaySessionError.unexpected(message: "No DRM config tracked for playbackID: \(playbackID)")
        }
        
        return try await self.requestLicenseInner(
            spcData: spcData,
            playbackID: playbackID,
            drmConfig: config
        )
    }
    
    private func lookUpDRMConfig(playbackID: String, online: Bool) async -> DRMConfig? {
        if online {
            return await onlineDRMConfigOnQueue(for: playbackID)
        } else {
            return await offlineDRMConfigOnQueue(for: playbackID)
        }
    }
    
    /// Requests the App Certificate for a playback id
    private func requestCertificateInner(
        playbackID: String,
        drmConfig config: DRMConfig
    ) async throws -> Data {
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
            throw error
            errorDispatcher.dispatchApplicationCertificateRequestError(
                error: error,
                playbackID: playbackID
            )
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        logger.debug(
            "Requesting application certificate from \(url, privacy: .auto(mask: .hash))"
        )
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                // probs not a reasonable case
                throw FairPlaySessionError.unexpected(message: "certificate data response was not HTTP response")
            }
            
            let responseCode = httpResponse.statusCode
            self.logger.debug(
                "Application certificate response code: \(httpResponse.statusCode)"
            )
            self.logger.debug(
                "Application certificate response headers: \(httpResponse.allHeaderFields, privacy: .auto(mask: .hash))"
            )

            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                self.logger.debug(
                    "Application certificate request failed with response code: \(String(describing: responseCode))"
                )
                
                // Error response should have worthwhile info
                if let utfData = String(data: data, encoding: .utf8) {
                    self.logger.debug("Application certificate error response: \(utfData)")
                }
                
                let error = FairPlaySessionError.httpFailed(
                    responseStatusCode: responseCode ?? 0
                )
                self.errorDispatcher.dispatchApplicationCertificateRequestError(
                    error: error,
                    playbackID: playbackID
                )
                throw error
            }
            
            // this edge case (200 with invalid data) is possible from our DRM vendor
            guard data.count > 0 else {
                let error = FairPlaySessionError.unexpected(message: "No cert data with 200 OK response")
                self.logger.debug(
                    "Application certificate request completed with missing data and response code \(responseCode)"
                )
                self.errorDispatcher.dispatchApplicationCertificateRequestError(
                    error: error,
                    playbackID: playbackID
                )
                throw error
            }
            
            // success!!
            self.logger.debug("Application certificate bytes: \(data.base64EncodedString())")
            return data
        } catch let error as FairPlaySessionError {
            throw error
        } catch {
            self.logger.debug(
                "Application certificate request failed with error: \(error.localizedDescription)"
            )
            let error = FairPlaySessionError.because(cause: error)
            self.errorDispatcher.dispatchApplicationCertificateRequestError(
                error: error,
                playbackID: playbackID
            )
            throw error
        }
    }

    /// Requests a license to play based on the given SPC data
    /// - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    private func requestLicenseInner(
        spcData: Data,
        playbackID: String,
        drmConfig config: DRMConfig
    ) async throws -> Data {

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
            errorDispatcher.dispatchLicenseRequestError(
                error: error,
                playbackID: playbackID
            )
            throw error
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
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                // probs not a real case
                throw FairPlaySessionError.unexpected(message: "license data response was not HTTP response")
            }
            let responseCode = httpResponse.statusCode
            
            // Server errors
            guard responseCode == 200 else {
                self.logger.error("CKC request failed: \(String(describing: responseCode))")
                if let errorBody = String(data: data, encoding: .utf8) {
                    self.logger.error("\t with body: \(errorBody)")
                }
                
                let error = FairPlaySessionError.httpFailed(responseStatusCode: responseCode ?? 0)
                self.errorDispatcher.dispatchLicenseRequestError(
                    error: error,
                    playbackID: playbackID
                )
                throw error
            }
            
            // strange edge case: 200 with no response body
            //  this happened because of a client-side encoding difference causing an error
            //  with our drm vendor and probably shouldn't be reachable, but lets not crash
            guard data.count > 0 else {
                let error = FairPlaySessionError.unexpected(message: "No license data with 200 response")
                self.logger.debug("No CKC data despite server returning success")
                self.errorDispatcher.dispatchLicenseRequestError(
                    error: error,
                    playbackID: playbackID
                )
                throw error
            }
            
            // success!
            self.logger.debug("License/CKC Data: \(data.base64EncodedString())")
            return data
            
        } catch let error as FairPlaySessionError {
            throw error
        } catch {
            self.logger.debug("URL Session Task Failed: \(error.localizedDescription)")
            let error = FairPlaySessionError.because(cause: error)
            self.errorDispatcher.dispatchLicenseRequestError(
                error: error,
                playbackID: playbackID
            )
            throw error
        }
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
