//
//  ContentKeySessionDelegate.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import AVFoundation
import CryptoKit
import Foundation
import os

class ContentKeySessionDelegate<SessionManager: FairPlayStreamingSessionCredentialClient & DRMAssetRegistry> : NSObject, AVContentKeySessionDelegate {

    weak var sessionManager: SessionManager?
    var logger: Logger

    private let _persistedKeyStore: PersistedKeyStore?

    private var persistedKeyStore: PersistedKeyStore {
        _persistedKeyStore ?? MuxOfflineAccessManager.shared.manager
    }

    private let _onlineLicenseCache: OnlineLicenseCaching?

    private var onlineLicenseCache: OnlineLicenseCaching {
        _onlineLicenseCache ?? OnlineDRMLicenseCache.shared
    }

    init(
        sessionManager: SessionManager,
        persistedKeyStore: PersistedKeyStore? = nil,
        onlineLicenseCache: OnlineLicenseCaching? = nil
    ) {
        self.sessionManager = sessionManager
        self.logger = sessionManager.logger
        self._persistedKeyStore = persistedKeyStore
        self._onlineLicenseCache = onlineLicenseCache
    }
    
    // MARK: AVContentKeySessionDelegate implementation
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didProvide keyRequest: AVContentKeyRequest
    ) {
        logger.trace("didProvide AVContentKeyRequest")
        Task {
            do {
                try await handleContentKeyRequest(request: DefaultKeyRequest(wrapping: keyRequest))
            } catch {
                keyRequest.processContentKeyResponseError(error)
            }
        }
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        logger.trace("didProvide AVPersistableContentKeyRequest")
        Task {
            do {
                try await handlePersistableContentKeyRequest(request: DefaultKeyRequest(wrapping: keyRequest))
            } catch {
                keyRequest.processContentKeyResponseError(error)
            }
        }
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didUpdatePersistableContentKey persistableContentKey: Data,
        forContentKeyIdentifier keyIdentifier: Any
    ) {
        logger.trace("contentKeySession: didUpdatePersistableContentKey")
        Task {
            do {
                try await handleContentKeyUpdated(keyIdentifier: keyIdentifier, data: persistableContentKey)
            } catch {
                // Delegate provides no way to notify of this
                logger.error("Failed to update content key: \(error)")
            }
        }
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest
    ) {
        logger.trace("didProvide didProvideRenewingContentKeyRequest")
        Task {
            do {
                try await handleContentKeyRequest(request: DefaultKeyRequest(wrapping: keyRequest))
            } catch {
                keyRequest.processContentKeyResponseError(error)
            }
        }
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
    
    func handleContentKeyUpdated(
        keyIdentifier: Any,
        data: Data
    ) async throws {
        logger.trace("\(#function) called")
        guard let requestIdentifierString = keyIdentifier as? String,
              let mediaPlaylistKeyURL = URL(string: requestIdentifierString)
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
            logger.debug("\(#function) Error: key SKD location missing playbackId [\(mediaPlaylistKeyURL.absoluteString)]")
            return
        }

        // Route the updated key to the right store: offline downloads persist
        // to the on-disk key store; online assets update the short-term license cache.
        if await sessionManager?.hasOfflineDRMConfig(playbackID: playbackID) == true {
            try await persistedKeyStore.savePersistedContentKey(
                playbackID: playbackID,
                identifier: requestIdentifierString,
                contentKeyData: data
            )
        } else {
            let credentials = await sessionManager?.onlineDRMCredentials(playbackID: playbackID)
            let fingerprint = Self.fingerprint(
                forToken: credentials?.drmToken,
                rootDomain: credentials?.rootDomain
            )
            await onlineLicenseCache.store(
                playbackID: playbackID,
                tokenFingerprint: fingerprint,
                ckc: data
            )
        }
    }
    
    func handlePersistableContentKeyRequest(request: any KeyRequest) async throws {
        logger.trace("\(#function) called")

        guard let sessionManager = self.sessionManager else {
            // could happen if recovering from media services crashing
            throw FairPlaySessionError.unexpected(message: "\(#function) called with terminated SessionManager")
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
            logger.debug("\(#function) Error: key SKD location missing playbackId [\(mediaPlaylistKeyURL.absoluteString)]")
            throw FairPlaySessionError.unexpected(message: "playbackID not present in key uri")
        }

        // An offline asset (downloading or playing back) uses the on-disk
        // download key store and drm_token-claims-based expiration. An online
        // asset uses the short-term online license cache.
        if await sessionManager.hasOfflineDRMConfig(playbackID: playbackID) {
            try await handleOfflinePersistableContentKeyRequest(
                request: request,
                sessionManager: sessionManager,
                playbackID: playbackID,
                requestIdentifierString: requestIdentifierString,
                contentIdentifier: utfEncodedRequestIdentifierString
            )
        } else {
            try await handleOnlineCachedContentKeyRequest(
                request: request,
                sessionManager: sessionManager,
                playbackID: playbackID,
                contentIdentifier: utfEncodedRequestIdentifierString
            )
        }
    }

    /// Offline download / playback path: serve a previously-persisted key if we
    /// have one, otherwise fetch a persistable license and save it to the
    /// download key store.
    private func handleOfflinePersistableContentKeyRequest(
        request: any KeyRequest,
        sessionManager: SessionManager,
        playbackID: String,
        requestIdentifierString: String,
        contentIdentifier: Data
    ) async throws {
        // If we already have a persisted content key, use it (this is the offline playback path)
        if let persistedContentKey = try await persistedKeyStore.findPersistedContentKey(playbackID: playbackID) {
            // Transition to playDuration-based expiration on first offline playback
            await persistedKeyStore.updateExpirationPhase(playbackID: playbackID, phase: .playDuration)
            request.processContentKeyResponse(
                request.makeContentKeyResponse(fairPlayStreamingKeyResponseData: persistedContentKey)
            )
            return
        }

        // No content key already? Try to get one
        let appCertData = try await sessionManager.requestCertificate(playbackID: playbackID, offline: true)
        let spcData = try await request.makeStreamingContentKeyRequestData(
            forApp: appCertData,
            contentIdentifier: contentIdentifier,
            options: [AVContentKeyRequestProtocolVersionsKey: [1]]
        )
        let ckcData = try await sessionManager.requestLicence(spcData: spcData, playbackID: playbackID, offline: true)

        let persistableKey = try request.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
        try await persistedKeyStore.savePersistedContentKey(
            playbackID: playbackID,
            identifier: requestIdentifierString,
            contentKeyData: persistableKey
        )

        request.processContentKeyResponse(
            request.makeContentKeyResponse(fairPlayStreamingKeyResponseData: persistableKey)
        )
    }

    /// Online playback path: reuse a cached license if one is still
    /// valid for the current `drm_token`, otherwise do the full handshake and
    /// cache the resulting persistable license for next time.
    private func handleOnlineCachedContentKeyRequest(
        request: any KeyRequest,
        sessionManager: SessionManager,
        playbackID: String,
        contentIdentifier: Data
    ) async throws {
        let credentials = await sessionManager.onlineDRMCredentials(playbackID: playbackID)
        let fingerprint = Self.fingerprint(
            forToken: credentials?.drmToken,
            rootDomain: credentials?.rootDomain
        )

        // Cache hit: reuse the persisted license, no network round trip.
        if let cachedLicense = await onlineLicenseCache.cachedLicense(
            playbackID: playbackID,
            tokenFingerprint: fingerprint
        ) {
            logger.debug("Using cached online license for \(playbackID, privacy: .public)")
            request.processContentKeyResponse(
                request.makeContentKeyResponse(fairPlayStreamingKeyResponseData: cachedLicense)
            )
            return
        }

        // Cache miss: do the handshake and cache the persistable license.
        let certData = try await sessionManager.requestCertificate(playbackID: playbackID, offline: false)
        let spcData = try await request.makeStreamingContentKeyRequestData(
            forApp: certData,
            contentIdentifier: contentIdentifier,
            options: [AVContentKeyRequestProtocolVersionsKey: [1]]
        )
        let ckcData = try await sessionManager.requestLicence(spcData: spcData, playbackID: playbackID, offline: false)

        let persistableKey = try request.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
        await onlineLicenseCache.store(
            playbackID: playbackID,
            tokenFingerprint: fingerprint,
            ckc: persistableKey
        )

        request.processContentKeyResponse(
            request.makeContentKeyResponse(fairPlayStreamingKeyResponseData: persistableKey)
        )
    }

    /// Stable fingerprint of the online DRM credentials so the cache invalidates
    /// when the token or root domain changes. Deliberately excludes the `skd://`
    /// key identifier (it can carry a per-session token, which would break
    /// cross-session caching); multi-key assets are a non-goal.
    static func fingerprint(forToken token: String?, rootDomain: String?) -> String {
        guard let token else { return "no-token" }
        let material = "\(rootDomain ?? "")\u{1f}\(token)"
        guard let data = material.data(using: .utf8) else { return "no-token" }
        return SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
    
    func handleContentKeyRequest(request: any KeyRequest) async throws {
        logger.debug(
            "Called \(#function)"
        )
        
        guard let sessionManager = self.sessionManager else {
            logger.debug("Missing session manager")
            return
        }

        // for hls, "the identifier must be an NSURL that matches a key URI in the Media Playlist." from the docs
        guard let requestIdentifierString = request.identifier as? String,
              let mediaPlaylistKeyURL = URL(string: requestIdentifierString),
              let utfEncodedRequestIdentifierString = requestIdentifierString.data(using: .utf8)
        else {
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
        
        let isOffline = await sessionManager.hasOfflineDRMConfig(playbackID: playbackID)

        // Use the persistable-key flow for both offline (required) and online
        // (so the license can be cached and reused). If it's unavailable
        // (AirPlay, or a session with no storage directory), fall back below to
        // a one-shot key.
        do {
            try request.respondByRequestingPersistableContentKeyRequestOnAnyOS()
            // No more processing here; we'll get a persistable key request next.
            return
        } catch {
            logger.debug("Persistable key request unavailable, using one-shot key: \(error.localizedDescription)")
        }

        // Fallback: one-shot (ephemeral) key, no caching. Use the asset's
        // offline token if it's an offline asset (not really supported, but
        // preserves prior behavior), otherwise the online token.
        let certData = try await sessionManager.requestCertificate(playbackID: playbackID, offline: isOffline)
        let spcData = try await request.makeStreamingContentKeyRequestData(
            forApp: certData,
            contentIdentifier: utfEncodedRequestIdentifierString,
            options: [AVContentKeyRequestProtocolVersionsKey: [1]]
        )
        let ckcData = try await sessionManager.requestLicence(spcData: spcData, playbackID: playbackID, offline: isOffline)

        // Send CKC to CDM/ContentKeySession so we can finally play our content
        logger.debug("Submitting CKC to system")
        request.processContentKeyResponse(
            request.makeContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
        )
        logger.debug("Protected content now available for processing")
        // Done! no further interaction is required from us to play.
   }
}

// Wraps a generic request for a key and delegates calls to it
//  this protocol's methods are intended to match AVContentKeyRequest
protocol KeyRequest {
    
    associatedtype InnerRequest
    
    var identifier: Any? { get }
    
    func makeContentKeyResponse(fairPlayStreamingKeyResponseData data: Data) -> AVContentKeyResponse
    
    func processContentKeyResponse(_ response: AVContentKeyResponse)
    func processContentKeyResponseError(_ error: any Error)
    func makeStreamingContentKeyRequestData(forApp appIdentifier: Data,
                                            contentIdentifier: Data?,
                                            options: [String : Any]?,
                                            completionHandler handler: @escaping (Data?, (any Error)?) -> Void)
    
    func makeStreamingContentKeyRequestData(forApp appIdentifier: Data,
                                            contentIdentifier: Data?,
                                            options: [String : Any]?
    ) async throws -> Data

    // Delegates to different methods depending on which platform we're on
    func respondByRequestingPersistableContentKeyRequestOnAnyOS() throws
    // note: key vendor response is a CKC for FairPlay
    func persistableContentKey(fromKeyVendorResponse: Data, options: [String: Any]?) throws -> Data
}

// Wraps a real AVContentKeyRequest and straightforwardly delegates to it
struct DefaultKeyRequest : KeyRequest {
    
    typealias InnerRequest = AVContentKeyRequest
    
    var identifier: Any? {
        get {
            return self.request.identifier
        }
    }
    
    func makeContentKeyResponse(fairPlayStreamingKeyResponseData data: Data) -> AVContentKeyResponse {
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
    
    func makeStreamingContentKeyRequestData(
        forApp appIdentifier: Data,
        contentIdentifier: Data?,
        options: [String : Any]? = nil
    ) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.request.makeStreamingContentKeyRequestData(
                forApp: appIdentifier,
                contentIdentifier: contentIdentifier,
                options: options,
                completionHandler: { data, error in
                    if let data {
                        continuation.resume(returning: data)
                    } else if let error {
                        continuation.resume(throwing: error)
                    } else {
                        // probably not a real case, but we don't want to hang the request to the system
                        continuation.resume(throwing: FairPlaySessionError.unexpected(message: "No SPC data or error"))
                    }
                }
            )
        }
    }
    
    func respondByRequestingPersistableContentKeyRequestOnAnyOS() throws {
        #if os(iOS)
        try self.request.respondByRequestingPersistableContentKeyRequestAndReturnError()
        #else
        try self.request.respondByRequestingPersistableContentKeyRequest()
        #endif
    }
    
    func persistableContentKey(fromKeyVendorResponse: Data, options: [String: Any]?) throws -> Data {
        guard let persistableKeyRequest = self.request as? AVPersistableContentKeyRequest else {
            throw FairPlaySessionError.unexpected(message: "Attempted to process streaming key request as persistable request")
        }

        return try persistableKeyRequest.persistableContentKey(
            fromKeyVendorResponse: fromKeyVendorResponse,
            options: options
        )
    }

    let request: InnerRequest
    
    init(wrapping request: InnerRequest) {
        self.request = request
    }
}
