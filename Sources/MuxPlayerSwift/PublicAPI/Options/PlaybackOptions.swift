//
//  PlaybackOptions.swift
//

import Foundation

/// The max resolution tier you'd like your asset to be streamed at
public enum MaxResolutionTier {
    /// By default no resolution tier is specified and Mux
    /// selects the optimal resolution and bitrate based on
    /// network and player conditions.
    case `default`
    /// The asset will stream with a resolution that does
    /// not exceed 720p (720 x 1280)
    case upTo720p
    /// The asset will stream with a resolution that does
    /// not exceed 1080p (1080 x 1920)
    case upTo1080p
    /// The asset will stream with a resolution that does
    /// not exceed 1440p (1440 x 2560)
    case upTo1440p
    /// The asset will stream with a resolution that does
    /// not exceed 2160 (2160 x 4096)
    case upTo2160p
}

/// The min resolution tier you'd like your asset to be streamed at
public enum MinResolutionTier {
    /// By default no resolution tier is specified and Mux
    /// selects the optimal resolution and bitrate based on
    /// network and player conditions.
    case `default`
    /// The asset will stream with a resolution that does
    /// not exceed 480p (640 x 480)
    case atLeast480p
    /// The asset will stream with a resolution that does
    /// not exceed 540p (960 x 540)
    case atLeast540p
    /// The asset will stream with a resolution that does
    /// not exceed 7200p (1080 x 720)
    case atLeast720p
    /// The asset will stream with a resolution that does
    /// not exceed 1080p (1920 x 1080)
    case atLeast1080p
    /// The asset will stream with a resolution that does
    /// not exceed 2440p (2160 x 4096)
    case atLeast1440p
    /// The asset will stream with a resolution that does
    /// not exceed 2160 p(2560 x 1440)
    case atLeast2160p
}

public enum RenditionOrder {
    /// By default no rendition order is specified
    case `default`
    /// The asset will choose renditions in ascending order
    case ascending
    /// The asset will choose renditions in descending order
    case descending
}

extension MaxResolutionTier {
    var queryValue: String {
        switch self {
            case .default:
                return ""
            case .upTo720p:
                return "720p"
            case .upTo1080p:
                return "1080p"
            case .upTo1440p:
                return "1440p"
            case .upTo2160p:
                return "2160p"
        }
    }
}

extension MinResolutionTier {
    var queryValue: String {
        switch self {
        case .default:
            return ""
        case .atLeast480p:
            return "480p"
        case .atLeast540p:
            return "540p"
        case .atLeast720p:
            return "720p"
        case .atLeast1080p:
            return "1080p"
        case .atLeast1440p:
            return "1440p"
        case .atLeast2160p:
            return "2160p"
        }
    }
}

extension RenditionOrder {
    var queryValue: String {
        switch self {
        case .default:
            return ""
        case .ascending:
            return "asc"
        case .descending:
            return "desc"
        }
    }
}

/// Options for playback
public struct PlaybackOptions {

    struct PublicPlaybackOptions {

        var maximumResolutionTier: MaxResolutionTier
        var minimumResolutionTier: MinResolutionTier
        var renditionOrder: RenditionOrder

        var useRedundantStreams: Bool
    }

    struct SignedPlaybackOptions {
        var playbackToken: String
    }

    enum PlaybackPolicy {
        case `public`(PublicPlaybackOptions)
        case signed(SignedPlaybackOptions)
    }

    var playbackPolicy: PlaybackPolicy

    var customDomain: String?
}

extension PlaybackOptions {

    /// Initializes playback options for a public
    /// playback ID
    /// - Parameters:
    ///   - maximumResolutionTier: maximum resolution of the
    ///   video the player will download
    public init(
        maximumResolutionTier: MaxResolutionTier = .default,
        minimumResolutionTier: MinResolutionTier = .default,
        renditionOrder:RenditionOrder = .default
    ) {
        self.playbackPolicy = .public(
            PublicPlaybackOptions(
                maximumResolutionTier: maximumResolutionTier,
                minimumResolutionTier: minimumResolutionTier,
                renditionOrder: renditionOrder,
                useRedundantStreams: true
            )
        )
    }


    /// Initializes playback options for a public
    /// playback ID
    /// - Parameters:
    ///   ///   - customDomain: custom playback domain, custom domains
    ///   need to be configured as described [here](https://docs.mux.com/guides/video/use-a-custom-domain-for-streaming#use-your-own-domain-for-delivering-videos-and-images) first.
    ///   The custom domain argument must have the format:
    ///   media.example.com.
    ///
    ///   Based on the above example, constructed playback
    ///   URLs will use https://stream.media.example.com/ as
    ///   their base URL.
    ///   - maximumResolutionTier: maximum resolution of the
    ///   video the player will download
    public init(
        customDomain: String,
        maximumResolutionTier: MaxResolutionTier = .default,
        minimumResolutionTier: MinResolutionTier = .default,
        renditionOrder: RenditionOrder = .default
    ) {
        self.customDomain = customDomain
        self.playbackPolicy = .public(
            PublicPlaybackOptions(
                maximumResolutionTier: maximumResolutionTier,
                minimumResolutionTier: minimumResolutionTier,
                renditionOrder: renditionOrder,
                useRedundantStreams: true
            )
        )
    }

    /// Initializes playback options with a
    /// signed playback token
    /// - Parameter playbackToken: JSON web token signed
    /// with a signing key
    public init(
        playbackToken: String
    ) {
        self.playbackPolicy = .signed(
            SignedPlaybackOptions(
                playbackToken: playbackToken
            )
        )
    }


    /// Initializes playback options with a
    /// signed playback token
    /// - Parameters:
    ///   - customDomain: custom playback domain, custom domains
    ///   need to be configured as described [here](https://docs.mux.com/guides/video/use-a-custom-domain-for-streaming#use-your-own-domain-for-delivering-videos-and-images) first.
    ///   The custom domain argument must have the format:
    ///   media.example.com.
    ///
    ///   Based on the above example, constructed playback
    ///   URLs will use https://stream.media.example.com/ as
    ///   their base URL.
    ///   - playbackToken: JSON web token signed
    /// with a signing key
    public init(
        customDomain: String,
        playbackToken: String
    ) {
        self.customDomain = customDomain
        self.playbackPolicy = .signed(
            SignedPlaybackOptions(
                playbackToken: playbackToken
            )
        )
    }
}
