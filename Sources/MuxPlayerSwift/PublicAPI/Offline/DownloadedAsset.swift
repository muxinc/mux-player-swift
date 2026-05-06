//
//  DownloadedAsset.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation

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

    /// Returns an `AVPlayer` configured for offline playback, or nil if the asset isn't playable.
    ///
    /// The returned player uses locally cached media selections and disables AVPlayer's automatic
    /// media selection criteria so playback does not depend on network-only alternates.
    /// Returns nil when this downloaded asset's status is not `.playable`.
    public func makeOfflinePlayer() async throws -> AVPlayer? {
        guard let asset = avAssetIfPlayable() else { return nil }

        let item = AVPlayerItem(asset: asset)

        // Pre-select downloaded options so AVPlayer doesn't try to fetch
        // remote alternates that the asset's master playlist still references.
        if let cache = asset.assetCache {
            async let audibleGroupTask = asset.loadMediaSelectionGroup(for: .audible)
            async let legibleGroupTask = asset.loadMediaSelectionGroup(for: .legible)
            async let preferredSelectionTask = asset.load(.preferredMediaSelection)

            let preferredSelection = try await preferredSelectionTask

            if let group = try await audibleGroupTask,
               let downloadedAudio = OfflineMediaSelectionHelper.selectedCachedOption(
                    preferredOption: preferredSelection.selectedMediaOption(in: group),
                    cachedOptions: cache.mediaSelectionOptions(in: group),
                    fallbackToFirstCachedOption: true
               ) {
                item.select(downloadedAudio, in: group)
            }
            if let group = try await legibleGroupTask {
                let downloadedSubtitle = OfflineMediaSelectionHelper.selectedCachedOption(
                    preferredOption: preferredSelection.selectedMediaOption(in: group),
                    cachedOptions: cache.mediaSelectionOptions(in: group),
                    fallbackToFirstCachedOption: false
                )
                item.select(downloadedSubtitle, in: group)
            }
        }

        let player = AVPlayer(playerItem: item)
        player.appliesMediaSelectionCriteriaAutomatically = false
        return player
    }
}
