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
}
