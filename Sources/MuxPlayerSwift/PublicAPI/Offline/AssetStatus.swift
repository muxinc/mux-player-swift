//
//  AssetStatus.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation

/// The status of a downloaded asset
@available(tvOS, unavailable, message: "Offline downloads are unavailable on tvOS.")
public enum AssetStatus {
    /// The asset is ready to play
    case playable(asset: AVURLAsset)
    /// The asset needs to be re-downloaded when online
    case redownloadWhenOnline
    /// The asset's playback period has expired. This value is only applicable to DRM-protected content
    case expired
}
