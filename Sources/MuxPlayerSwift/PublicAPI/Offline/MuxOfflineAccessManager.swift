//
//  MuxOfflineAccessManager.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation
import os

/// Manager for downloading and accessing Mux video content for offline playback
public class MuxOfflineAccessManager {
    public static let shared = MuxOfflineAccessManager()
    
    private let manager: DownloadManager = DownloadManager()
    
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
            .startDownloadWithPublisher(playbackID: playbackID, avAsset: asset, options: downloadOptions)
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
}
