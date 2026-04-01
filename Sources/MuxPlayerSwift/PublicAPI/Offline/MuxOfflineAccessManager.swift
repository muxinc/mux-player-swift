//
//  MuxOfflineAccessManager.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation
import Combine
import os

/// Manager for downloading and accessing Mux video content for offline playback
public class MuxOfflineAccessManager {
    public static let shared = MuxOfflineAccessManager()
    
    private lazy var manager: DownloadManager = DownloadManager()
    
    #if DEBUG
    private let logger = Logger(OSLog(subsystem: "com.mux.player", category: "Mux-Offline"))
    #else
    private let logger = Logger(.disabled)
    #endif
    
    /// Start downloading a video for offline access
    /// - Parameters:
    ///   - playbackID: The Mux playback ID
    ///   - playbackOptions: Configuration for playback
    ///   - downloadOptions: Configuration for the download
    /// - Returns: A publisher that emits download events
    public func startDownload(
        playbackID: String,
        playbackOptions: PlaybackOptions,
        downloadOptions: DownloadOptions
    ) async -> AnyPublisher<DownloadEvent, Error> {
        let urlComponents = URLComponents(playbackID: playbackID, playbackOptions: playbackOptions)
        guard let url = urlComponents.url else {
            // If our own URLComponents init returns a poorly-formed URLComponents, fail (but this will not happen in practice)
            logger.error("[Mux-Offline] internal error: Invalid URL constructed for playbackID: \(playbackID)")
            return Fail<DownloadEvent, Error>(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let asset = AVURLAsset(url: url)
        return await manager.startDownloadWithPublisher(playbackID: playbackID, avAsset: asset, options: downloadOptions)
    }
    
    /// Start downloading a video for offline access.
    /// Only one download per playbackID may be saved at once. If you want to re-download media for the same playbackID
    /// (eg, to recover from token expiration, or with different options), call ``removeDownload(playbackID:)`` first
    ///
    /// - Parameters:
    ///   - playbackID: The Mux playback ID
    ///   - playbackOptions: Configuration for playback
    ///   - downloadOptions: Configuration for the download
    /// - Returns: An async stream that emits download events
    public func startDownloadAsync(
        playbackID: String,
        playbackOptions: PlaybackOptions,
        downloadOptions: DownloadOptions
    ) async -> AsyncThrowingStream<DownloadEvent, Error> {
        let publisher = await startDownload(
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            downloadOptions: downloadOptions
        )
        return publisher.toAsyncThrowingStream()
    }
    
    /// Observe an already started download
    /// - Parameter playbackID: The Mux playback ID
    /// - Returns: A publisher that emits download events, or nil if no download is in progress
    public func observeStartedDownload(playbackID: String) async -> AnyPublisher<DownloadEvent, Error>? {
        return await manager.publisherForDownload(playbackID: playbackID)
    }
    
    /// Observe an already started download
    /// - Parameter playbackID: The Mux playback ID
    /// - Returns: An async stream that emits download events, or nil if no download is in progress
    public func observeStartedDownloadAsync(playbackID: String) async -> AsyncThrowingStream<DownloadEvent, Error>? {
        guard let publisher = await observeStartedDownload(playbackID: playbackID) else {
            return nil
        }
        return publisher.toAsyncThrowingStream()
    }
    
    /// Resume any pending download tasks from last app session
    public func resumePendingDownloadTasks() {
        Task { await manager.reattachPendingDownloadPublishers() }
    }
    
    /// Resume any pending download tasks from last app session
    /// - Returns: A dictionary mapping playback IDs to publishers of download events
    public func resumePendingDownloadsWithEvents() async -> [String: AnyPublisher<DownloadEvent, Error>] {
        return await manager.reattachPendingDownloadPublishers()
    }
    
    /// Resume any pending download tasks from last app session, returning AsyncThrowingStreams
    /// - Returns: A dictionary mapping playback IDs to async streams of download events
    public func resumePendingDownloadsWithEventsAsync() async -> [String: AsyncThrowingStream<DownloadEvent, Error>] {
        let publishers = await resumePendingDownloadsWithEvents()
        return publishers.mapValues { $0.toAsyncThrowingStream() }
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


