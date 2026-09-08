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

    func requestCertificate(playbackID: String, offline: Bool) async throws -> Data

    func requestLicence(spcData: Data, playbackID: String, offline: Bool) async throws -> Data

    var logger: Logger { get set }
}

// Intended for registering drm-protected AVURLAssets
protocol DRMAssetRegistry {
    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String)

    func addOfflineDownloadDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String)
    func removeOfflineDownloadSession(playbackID: String)
    /// Re-runs the FairPlay handshake for an already-downloaded asset using a
    /// freshly-supplied `drm_token`, with no player and no `AVURLAsset` recipient.
    /// Returns once the new license has been persisted, or throws if it couldn't be.
    func renewOfflineLicense(playbackID: String, keyIdentifier: String, drmToken: String, rootDomain: String) async throws
    /// Whether a ``renewOfflineLicense(playbackID:keyIdentifier:drmToken:rootDomain:)``
    /// call is awaiting a key for this playbackID. Key requests for a renewal must
    /// bypass the already-persisted key and fetch a new one.
    func isRenewingOfflineLicense(playbackID: String) async -> Bool
    /// Reports the outcome of a renewal key request back to the waiting
    /// ``renewOfflineLicense(playbackID:keyIdentifier:drmToken:rootDomain:)`` call.
    func finishOfflineLicenseRenewal(playbackID: String, result: Result<Void, Error>)
    func addOfflinePlayDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, keyData: Data) async
    func hasOfflineDRMConfig(playbackID: String) async -> Bool
    func offlineKeyData(playbackID: String) async -> Data?
    /// The `drm_token` and root domain tracked for an *online* DRM asset, if
    /// any. Used to fingerprint the request so the online license cache can
    /// invalidate when the app supplies a new token (or domain) for the same
    /// playbackID.
    func onlineDRMCredentials(playbackID: String) async -> (drmToken: String, rootDomain: String)?
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

    // Starts a key request for an identifier directly, without an
    // AVContentKeyRecipient. Used to fetch a key with no player involved.
    func processContentKeyRequest(withIdentifier identifier: Any?, initializationData: Data?, options: [String: Any]?)

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

/// Ceiling on each of a renewal's credential requests (app certificate, then
/// license). Renewal is interactive, so these fail fast instead of waiting for
/// connectivity the way a download does.
private let offlineLicenseRenewalRequestTimeout: TimeInterval = 30

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
    /// should be accessed on `queue`. playbackIDs with a license renewal in
    /// flight. Kept separately from `offlineDownloadKeyLookup` because saving a
    /// key tears that entry down while the renewal is still finishing up.
    private var renewingPlaybackIDs: Set<String> = []
    /// should be accessed on `queue`. Callers waiting on a renewal's key request.
    /// Removed from this table before being resumed, so each is resumed once.
    private var renewalContinuations: [String: CheckedContinuation<Void, Error>] = [:]

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
    /// Used in place of `urlSession` for license renewals, which fail fast rather
    /// than waiting for connectivity. See the initializer.
    private let renewalURLSession: URLSession

    /// The session to make credential requests for this playbackID on.
    private func urlSession(forPlaybackID playbackID: String) async -> URLSession {
        return await isRenewingOfflineLicense(playbackID: playbackID) ? renewalURLSession : urlSession
    }

    private func drmConfigOnQueue(for playbackID: String, offline: Bool) async -> DRMConfig? {
        return await withCheckedContinuation { continuation in
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("looked up DRMConfig after cleanup")
                    continuation.resume(returning: nil)
                    return
                }
                let lookup = offline ? offlineDownloadKeyLookup : onlineKeyConfigLookup
                continuation.resume(returning: lookup[playbackID])
            }
        }
    }

    // MARK: Requesting licenses and certs

    func requestCertificate(playbackID: String, offline: Bool) async throws -> Data {
        guard let config = await drmConfigOnQueue(for: playbackID, offline: offline) else {
            throw FairPlaySessionError.unexpected(message: "No DRM config tracked for playbackID: \(playbackID)")
        }

        return try await requestCertificateInner(
            playbackID: playbackID,
            drmConfig: config,
            urlSession: await urlSession(forPlaybackID: playbackID)
        )
    }

    func requestLicence(spcData: Data, playbackID: String, offline: Bool) async throws -> Data {
        guard let config = await drmConfigOnQueue(for: playbackID, offline: offline) else {
            throw FairPlaySessionError.unexpected(message: "No DRM config tracked for playbackID: \(playbackID)")
        }

        return try await requestLicenseInner(
            spcData: spcData,
            playbackID: playbackID,
            drmConfig: config,
            urlSession: await urlSession(forPlaybackID: playbackID)
        )
    }

    /// Requests the App Certificate for a playback id
    private func requestCertificateInner(
        playbackID: String,
        drmConfig config: DRMConfig,
        urlSession: URLSession
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
            errorDispatcher.dispatchApplicationCertificateRequestError(
                error: error,
                playbackID: playbackID
            )
            throw error
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        logger.debug(
            "Requesting application certificate from \(url, privacy: .auto(mask: .hash))"
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            logger.debug(
                "Application certificate request failed with error: \(error.localizedDescription)"
            )
            let fpsError = FairPlaySessionError.because(cause: error)
            errorDispatcher.dispatchApplicationCertificateRequestError(
                error: fpsError,
                playbackID: playbackID
            )
            throw fpsError
        }

        logger.debug(
            "Application certificate request completed"
        )

        if let httpResponse = response as? HTTPURLResponse {
            logger.debug(
                "Application certificate response code: \(httpResponse.statusCode)"
            )
            logger.debug(
                "Application certificate response headers: \(httpResponse.allHeaderFields, privacy: .auto(mask: .hash))"
            )
            if let utfData = String(data: data, encoding: .utf8) {
                logger.debug(
                    "Application certificate data: \(utfData)"
                )
            }

            // error case: I/O finished with non-successful response
            guard httpResponse.statusCode == 200 else {
                logger.debug(
                    "Application certificate request failed with response code: \(httpResponse.statusCode)"
                )
                let error = FairPlaySessionError.httpFailed(
                    responseStatusCode: httpResponse.statusCode
                )
                errorDispatcher.dispatchApplicationCertificateRequestError(
                    error: error,
                    playbackID: playbackID
                )
                throw error
            }
        }

        // this edge case (200 with invalid data) is possible from our DRM vendor
        guard data.count > 0 else {
            let error = FairPlaySessionError.unexpected(
                message: "No cert data with 200 OK response"
            )
            logger.debug(
                "Application certificate request completed with missing data"
            )
            errorDispatcher.dispatchApplicationCertificateRequestError(
                error: error,
                playbackID: playbackID
            )
            throw error
        }

        logger.debug("Application certificate response data:\(data.base64EncodedString(), privacy: .auto(mask: .hash))")

        return data
    }

    /// Requests a license to play based on the given SPC data
    private func requestLicenseInner(
        spcData: Data,
        playbackID: String,
        drmConfig config: DRMConfig,
        urlSession: URLSession
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
        request.httpMethod = "POST"
        request.httpBody = spcData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(String(format: "%lu", request.httpBody?.count ?? 0), forHTTPHeaderField: "Content-Length")
        logger.debug("Sending License/CKC Request to: \(request.url?.absoluteString ?? "nil")")
        logger.debug("\t with header fields: \(String(describing: request.allHTTPHeaderFields))")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            logger.debug(
                "URL Session Task Failed: \(error.localizedDescription)"
            )
            let fpsError = FairPlaySessionError.because(cause: error)
            errorDispatcher.dispatchLicenseRequestError(
                error: fpsError,
                playbackID: playbackID
            )
            throw fpsError
        }

        if let httpResponse = response as? HTTPURLResponse {
            logger.debug(
                "License response code: \(httpResponse.statusCode)"
            )
            logger.debug(
                "License response headers: \(httpResponse.allHeaderFields, privacy: .auto(mask: .hash))"
            )

            // error case: I/O finished with non-successful response
            guard httpResponse.statusCode == 200 else {
                logger.debug(
                    "CKC request failed: \(httpResponse.statusCode)"
                )
                let error = FairPlaySessionError.httpFailed(
                    responseStatusCode: httpResponse.statusCode
                )
                errorDispatcher.dispatchLicenseRequestError(
                    error: error,
                    playbackID: playbackID
                )
                throw error
            }
        }

        // strange edge case: 200 with no response body
        //  this happened because of a client-side encoding difference causing an error
        //  with our drm vendor and probably shouldn't be reachable, but lets not crash
        guard data.count > 0 else {
            let error = FairPlaySessionError.unexpected(message: "No license data with 200 response")
            logger.debug("No CKC data despite server returning success")
            errorDispatcher.dispatchLicenseRequestError(
                error: error,
                playbackID: playbackID
            )
            throw error
        }

        return data
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

    // MARK: renewing offline licenses

    func renewOfflineLicense(
        playbackID: String,
        keyIdentifier: String,
        drmToken: String,
        rootDomain: String
    ) async throws {
        guard await beginRenewal(playbackID: playbackID) else {
            throw FairPlaySessionError.renewalAlreadyInProgress(playbackID: playbackID)
        }

        // A fresh session per renewal, so the key request can't be satisfied by
        // state left over from an earlier flow. There's no AVURLAsset recipient
        // here; the key identifier drives the request instead.
        let session = contentKeySession.recreate()
        let delegate = ContentKeySessionDelegate(sessionManager: self)
        session.setDelegate(delegate, queue: queue)

        defer {
            session.setDelegate(nil, queue: nil)
            removeOfflineDownloadSession(playbackID: playbackID)
            queue.async { [weak self] in
                self?.renewingPlaybackIDs.remove(playbackID)
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("attempted a license renewal after cleanup")
                    continuation.resume(
                        throwing: FairPlaySessionError.unexpected(message: "Session manager terminated")
                    )
                    return
                }
                // The delegate callbacks need these before the flow starts. Only
                // the drm_token is needed to reach the cert and license hosts,
                // so there's no playback token to supply here.
                offlineDownloadKeyLookup[playbackID] = DRMConfig(
                    options: PlaybackOptions.DRMPlaybackOptions(
                        playbackToken: "",
                        drmToken: drmToken
                    ),
                    rootDomain: rootDomain
                )
                downloadKeySessions[playbackID] = session
                downloadKeyDelegates[playbackID] = delegate
                renewalContinuations[playbackID] = continuation

                session.processContentKeyRequest(
                    withIdentifier: keyIdentifier,
                    initializationData: nil,
                    options: nil
                )
            }
        }
    }

    func isRenewingOfflineLicense(playbackID: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                continuation.resume(returning: self?.renewingPlaybackIDs.contains(playbackID) ?? false)
            }
        }
    }

    func finishOfflineLicenseRenewal(playbackID: String, result: Result<Void, Error>) {
        queue.async { [weak self] in
            // Removing before resuming keeps this a single resume per renewal,
            // no matter how many callers report an outcome
            guard let continuation = self?.renewalContinuations.removeValue(forKey: playbackID) else {
                return
            }
            continuation.resume(with: result)
        }
    }

    /// Claims the renewal slot for a playbackID, returning false if one is
    /// already in flight.
    private func beginRenewal(playbackID: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self, !renewingPlaybackIDs.contains(playbackID) else {
                    continuation.resume(returning: false)
                    return
                }
                renewingPlaybackIDs.insert(playbackID)
                continuation.resume(returning: true)
            }
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
    
    func hasOfflineDRMConfig(playbackID: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("looked up offline DRM config after cleanup")
                    continuation.resume(returning: false)
                    return
                }
                let result = offlinePlayLookup[playbackID] != nil || offlineDownloadKeyLookup[playbackID] != nil
                continuation.resume(returning: result)
            }
        }
    }
    
    func offlineKeyData(playbackID: String) async -> Data? {
        return await withCheckedContinuation { continuation in
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("looked up offline key data after cleanup")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: offlinePlayLookup[playbackID])
            }
        }
    }

    func onlineDRMCredentials(playbackID: String) async -> (drmToken: String, rootDomain: String)? {
        return await withCheckedContinuation { continuation in
            queue.async { [logger, weak self] in
                guard let self else {
                    logger.warning("looked up online DRM credentials after cleanup")
                    continuation.resume(returning: nil)
                    return
                }
                if let config = onlineKeyConfigLookup[playbackID] {
                    continuation.resume(returning: (config.options.drmToken, config.rootDomain))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
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
            self.renewingPlaybackIDs.removeAll()
            // No key request is going to arrive for these now
            let abandonedRenewals = self.renewalContinuations
            self.renewalContinuations.removeAll()
            for (playbackID, continuation) in abandonedRenewals {
                continuation.resume(
                    throwing: FairPlaySessionError.unexpected(
                        message: "Media services were lost while renewing the offline license for \(playbackID)"
                    )
                )
            }
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

        // Renewals are interactive: an app asks for one believing it's online, and
        // waits on the result. Waiting for connectivity would leave that caller
        // hanging (the default resource timeout is measured in days), so a renewal
        // fails fast instead and lets the app try again later.
        let renewalURLSessionConfiguration = baseURLSessionConfig.copy() as! URLSessionConfiguration
        renewalURLSessionConfiguration.waitsForConnectivity = false
        renewalURLSessionConfiguration.networkServiceType = .responsiveData
        renewalURLSessionConfiguration.timeoutIntervalForRequest = offlineLicenseRenewalRequestTimeout
        renewalURLSessionConfiguration.timeoutIntervalForResource = offlineLicenseRenewalRequestTimeout

        renewalURLSession = URLSession(
            configuration: renewalURLSessionConfiguration,
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
    /// A license renewal was requested for a playbackID that already has one in
    /// flight. Distinct from the other cases because nothing went wrong: the
    /// earlier renewal is still running and this request was simply declined.
    case renewalAlreadyInProgress(playbackID: String)
}
