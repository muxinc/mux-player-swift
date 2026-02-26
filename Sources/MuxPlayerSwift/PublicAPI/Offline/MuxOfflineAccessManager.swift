//
//  MuxOfflineAccessManager.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation
import Combine

/// Manager for downloading and accessing Mux video content for offline playback
public class MuxOfflineAccessManager {
    public static let shared = MuxOfflineAccessManager()
    
    private lazy var manager: DownloadManager = DownloadManager()
    
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
        let url = URLComponents(playbackID: playbackID, playbackOptions: playbackOptions).url!
        let asset = AVURLAsset(url: url)
        return await manager.startDownloadWithPublisher(playbackID: playbackID, avAsset: asset, options: downloadOptions)
    }
    
    /// Start downloading a video for offline access
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

// MARK: - Public Types

/// Options for configuring a download
public struct DownloadOptions {
    /// A human-readable title for the download
    public let readableTitle: String
    /// Optional poster image data
    public let posterData: Data?
    /// Language codes for subtitles (e.g., 'en' or 'en-US')
    public let subtitleLanguages: [String]?
    /// Language codes for secondary audio tracks (e.g., 'en' or 'en-US')
    public let secondaryAudioLanguages: [String]?
    
    public init(readableTitle: String) {
        self.readableTitle = readableTitle
        
        self.posterData = nil
        self.subtitleLanguages = nil
        self.secondaryAudioLanguages = nil
    }
}

/// Events emitted during a download
public enum DownloadEvent {
    /// The download has started
    case started
    /// The download is waiting for network connectivity
    case waitingForConnectivity
    /// Progress update with percentage complete
    case progress(percent: Double)
    /// The download has completed successfully
    case completed(DownloadedAsset)
}

/// A downloaded video asset
public struct DownloadedAsset {
    /// The Mux playback ID
    public let playbackID: String
    /// The current status of the asset
    public let assetStatus: AssetStatus
    /// The options used when downloading
    public let downloadOptions: DownloadOptions
    
    /// Returns the AVURLAsset if the asset is playable, nil otherwise
    public func avAssetIfPlayable() -> AVURLAsset? {
        if case .playable(asset: let asset) = assetStatus {
            return asset
        } else {
            return nil
        }
    }
}

/// The status of a downloaded asset
public enum AssetStatus {
    /// The asset is ready to play
    case playable(asset: AVURLAsset)
    /// The asset needs to be re-downloaded when online
    case redownloadWhenOnline
    /// The asset has expired
    case expired
}

