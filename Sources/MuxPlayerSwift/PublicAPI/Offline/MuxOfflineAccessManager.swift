//
//  MuxOfflineAccessManager.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation
import os

#if os(iOS)

/// Manager for downloading and accessing Mux video content for offline playback
public class MuxOfflineAccessManager {
    public static let shared = MuxOfflineAccessManager()
    
    internal let manager: DownloadManager = DownloadManager()
    
#if DEBUG
    private let logger = Logger(OSLog(subsystem: "com.mux.player", category: "Mux-Offline"))
#else
    private let logger = Logger(.disabled)
#endif
    
    /// Start downloading a video for offline access.
    /// Only one download per playbackID may be saved at once. If you want to re-download media for the same playbackID
    /// (eg, to recover from token expiration, or with different options), call ``removeDownload(playbackID:)`` first
    ///
    /// - Parameters:
    ///   - playbackID: The Mux playback ID
    ///   - playbackOptions: Configuration for playback
    ///   - downloadOptions: Configuration for the download
    /// - Returns: An async stream that emits download events
    public func startDownload(
        playbackID: String,
        playbackOptions: PlaybackOptions,
        downloadOptions: DownloadOptions
    ) async -> AsyncThrowingStream<DownloadEvent, Error> {
        let urlComponents = URLComponents(playbackID: playbackID, playbackOptions: playbackOptions)
        guard let url = urlComponents.url else {
            // If our own URLComponents init returns a poorly-formed URLComponents, fail (but this will not happen in practice)
            logger.error("[Mux-Offline] internal error: Invalid URL constructed for playbackID: \(playbackID)")
            return AsyncThrowingStream { $0.finish(throwing: URLError(.badURL))}
        }
        
        let asset = AVURLAsset(url: url)
        
        return await manager
            .startDownloadWithPublisher(
                playbackID: playbackID,
                avAsset: asset,
                downloadOptions: downloadOptions,
                playbackOptions: playbackOptions
            )
            .toAsyncThrowingStream()
    }

    /// Observe an already started download
    /// - Parameter playbackID: The Mux playback ID
    /// - Returns: An async stream that emits download events, or nil if no download is in progress
    public func observeStartedDownload(playbackID: String) async -> AsyncThrowingStream<DownloadEvent, Error>? {
        return await manager.publisherForDownload(playbackID: playbackID)?.toAsyncThrowingStream()
    }
    
    /// Gets publishers for all in-progress tasks
    public func allInProcessTasks() async -> [String: AsyncThrowingStream<DownloadEvent, Error>] {
        return await manager.allInProgressTasks().mapValues { $0.toAsyncThrowingStream() }
    }
    
    /// Resume any pending download tasks from last app session
    public func resumePendingDownloadTasks() {
        Task { await manager.reattachPendingDownloadPublishers() }
    }
    
    /// Remove a downloaded video
    /// - Parameter playbackID: The Mux playback ID
    public func removeDownload(playbackID: String) async {
        await manager.removeDownload(playbackID: playbackID)
    }
    
    /// Renew the DRM license of an already-downloaded video, extending how long
    /// it stays playable offline without re-downloading the media
    ///
    /// Call this while online and any time you like — an asset whose license
    /// has already expired can be renewed just as well as one that hasn't.
    ///
    /// - Parameters:
    ///   - playbackID: The Mux playback ID of a completed, DRM-protected download
    ///   - drmToken: A freshly-minted JSON web token for DRM playback, signed for
    ///   offline use
    ///   - customDomain: Custom playback domain, in the format
    ///   media.example.com. Pass the same one you downloaded the asset with, so
    ///   the license is requested from the same host that issued the original.
    /// - Returns: The asset with its renewed license, playable again if it had expired
    /// - Throws: ``OfflineLicenseRenewalError`` if the asset can't be renewed, or
    /// if the license request fails
    @discardableResult
    public func renewOfflineLicense(
        playbackID: String,
        drmToken: String,
        customDomain: String? = nil
    ) async throws -> DownloadedAsset {
        return try await manager.renewOfflineLicense(
            playbackID: playbackID,
            drmToken: drmToken,
            customDomain: customDomain
        )
    }

    /// Find a downloaded asset by playback ID
    /// - Parameter playbackID: The Mux playback ID
    /// - Returns: The downloaded asset if found, nil otherwise
    public func findDownloadedAsset(playbackID: String) async -> DownloadedAsset? {
        return await manager.findDownloadedAsset(playbackID: playbackID)
    }

    /// Get all downloaded assets
    /// - Returns: An array of all downloaded assets
    public func allDownloadedAssets() async -> [DownloadedAsset] {
        return await manager.allCompletedAssets()
    }
    
    internal init() {
        PlayerSDK.shared.diagnosticsLogger.info("initializing MuxOfflineAccessManager")
    }
}

#elseif os(tvOS)

/// Offline downloads are unavailable on tvOS because AVFoundation doesn't
/// provide its asset-download APIs on that platform.
@available(tvOS, unavailable, message: "Offline downloads are unavailable on tvOS.")
public final class MuxOfflineAccessManager {}

#endif
