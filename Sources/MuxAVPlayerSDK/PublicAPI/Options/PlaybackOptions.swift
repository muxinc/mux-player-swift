//
//  PlaybackOptions.swift
//

import Foundation

/// The resolution tier you'd like your asset to be streamed at
enum ResolutionTier {
    /// By default no resolution tier is specified and Mux
    /// selects the optimal resolution and bitrate based on
    /// network and player conditions.
    case `default`
    /// The asset will stream with a resolution that does
    /// not exceed 720p (720 x 1280)
    case upTo720p
}

/// Options for playback
struct PlaybackOptions {

    /// The resolution tier for playback
    var resolutionTier: ResolutionTier

    /// Uses either CDN to stream your video
    var useRedundantStreams: Bool
}
