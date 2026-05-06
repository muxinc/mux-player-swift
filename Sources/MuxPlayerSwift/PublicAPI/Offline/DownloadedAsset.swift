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

    /// Returns an `AVPlayer` configured for reliable offline playback, or nil if
    /// the asset isn't playable.
    ///
    /// Two things are done that would otherwise be the caller's responsibility:
    ///
    /// 1. `appliesMediaSelectionCriteriaAutomatically` is disabled. Without this,
    ///    AVPlayer applies iOS's persisted user preferences (e.g. last-selected
    ///    subtitle language) to the player item — including preferences for
    ///    tracks that weren't downloaded. The player would then attempt remote
    ///    fetches and stall offline.
    /// 2. The player item's media selection is explicitly set to options that
    ///    are present in the local asset cache. Without this, the item inherits
    ///    its initial selection from the asset's `preferredMediaSelection`,
    ///    which can include non-downloaded tracks and cause seek operations to
    ///    hang waiting for remote segments that can't be fetched.
    ///
    /// The returned player is paused; call `play()` when ready to start playback.
    public func makeOfflinePlayer() async throws -> AVPlayer? {
        guard let asset = avAssetIfPlayable() else { return nil }

        let item = AVPlayerItem(asset: asset)

        // Pre-select downloaded options so AVPlayer doesn't try to fetch
        // remote alternates that the asset's master playlist still references.
        if let cache = asset.assetCache {
            async let audibleGroupTask = asset.loadMediaSelectionGroup(for: .audible)
            async let legibleGroupTask = asset.loadMediaSelectionGroup(for: .legible)

            if let group = try await audibleGroupTask,
               let downloadedAudio = cache.mediaSelectionOptions(in: group).first {
                item.select(downloadedAudio, in: group)
            }
            if let group = try await legibleGroupTask {
                // nil if no subtitle was downloaded — explicitly off
                let downloadedSubtitle = cache.mediaSelectionOptions(in: group).first
                item.select(downloadedSubtitle, in: group)
            }
        }

        let player = AVPlayer(playerItem: item)
        player.appliesMediaSelectionCriteriaAutomatically = false
        return player
    }
}
