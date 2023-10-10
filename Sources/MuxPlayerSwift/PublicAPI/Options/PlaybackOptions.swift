//
//  PlaybackOptions.swift
//

import Foundation

/// The resolution tier you'd like your asset to be streamed at
public enum ResolutionTier {
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
    /// not exceed 2160 (2160 x 4096)
    case upTo2160p
}

extension ResolutionTier {
    var queryValue: String {
        switch self {
            case .default:
                return ""
            case .upTo720p:
                return "720p"
            case .upTo1080p:
                return "1080p"
            case .upTo2160p:
                return "2160p"
        }
    }
}

/// Options for playback
public struct PlaybackOptions {

    struct PublicPlaybackOptions {

        var maximumResolutionTier: ResolutionTier


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
        maximumResolutionTier: ResolutionTier = .default
    ) {
        self.playbackPolicy = .public(
            PublicPlaybackOptions(
                maximumResolutionTier: maximumResolutionTier,
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
        maximumResolutionTier: ResolutionTier = .default
    ) {
        self.customDomain = customDomain
        self.playbackPolicy = .public(
            PublicPlaybackOptions(
                maximumResolutionTier: maximumResolutionTier,
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
