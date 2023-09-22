//
//  AVPlayerItem+Mux.swift
//

import AVFoundation
import Foundation

fileprivate func makePlaybackURL(
    playbackID: String,
    playbackOptions: PlaybackOptions
) -> URL {

    var components = URLComponents()
    components.scheme = "https"

    if let customDomain = playbackOptions.customDomain {
        components.host = "stream.\(customDomain)"
    } else {
        components.host = "stream.mux.com"
    }

    components.path = "/\(playbackID).m3u8"

    if case PlaybackOptions.PlaybackPolicy.public(let publicPlaybackOptions) = playbackOptions.playbackPolicy {
        var queryItems: [URLQueryItem] = []

        if publicPlaybackOptions.useRedundantStreams {
            queryItems.append(
                URLQueryItem(
                    name: "redundant_streams",
                    value: "true"
                )
            )
        }

        if publicPlaybackOptions.maximumResolutionTier != .default {
            queryItems.append(
                URLQueryItem(
                    name: "max_resolution",
                    value: publicPlaybackOptions.maximumResolutionTier.queryValue
                )
            )
        }

        components.queryItems = queryItems
    } else if case PlaybackOptions.PlaybackPolicy.signed(let signedPlaybackOptions) = playbackOptions.playbackPolicy {

        var queryItems: [URLQueryItem] = []

        queryItems.append(
            URLQueryItem(
                name: "token",
                value: signedPlaybackOptions.playbackToken
            )
        )

        components.queryItems = queryItems

    }

    guard let playbackURL = components.url else {
        preconditionFailure("Invalid playback URL components")
    }

    return playbackURL
}

internal extension AVPlayerItem {

    /// Initializes a player item with a playback URL that
    /// references your Mux Video at the supplied playback ID.
    /// The playback ID must be public.
    ///
    /// This initializer uses https://stream.mux.com as the
    /// base URL. Use a different initializer if using a custom
    /// playback URL.
    ///
    /// - Parameter playbackID: playback ID of the Mux Asset
    /// you'd like to play
    convenience init(playbackID: String) {
        let playbackURL = makePlaybackURL(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions()
        )

        self.init(url: playbackURL)
    }

    /// Initializes a player item with a playback URL that
    /// references your Mux Video at the supplied playback ID.
    /// The playback ID must be public.
    ///
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    convenience init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        let playbackURL = makePlaybackURL(
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )

        self.init(url: playbackURL)
    }

    /// Initializes a player item with a playback URL that
    /// references your Mux Video at the supplied playback ID.
    /// The playback ID must have a signed playback policy.
    ///
    /// - Parameters:
    ///     - signedPlaybackID: playback ID of the Mux Asset
    ///     you'd like to play
    ///     - token: JSON Web Token containing signed playback
    ///     claims
    convenience init(
        signedPlaybackID: String,
        token: String
    ) {
        guard let baseURL = URL(string: "https://stream.mux.com") else {
            preconditionFailure("Invalid base URL string")
        }

        var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        )
        components?.path = "/\(signedPlaybackID).m3u8"
        components?.queryItems = [
            URLQueryItem(
                name: "token",
                value: token
            )
        ]

        guard let playbackURL = components?.url else {
            preconditionFailure("Invalid playback URL components")
        }

        self.init(url: playbackURL)
    }

    /// Initializes a player item with a playback URL that
    /// references your Mux Video at the supplied playback ID.
    /// The playback ID must have a signed playback policy.
    ///
    /// Playback IDs that use referrer-based playback
    /// restrictions are not supported on iOS.
    ///
    /// - Parameters:
    ///     - signedPlaybackID: playback ID of the Mux Asset
    ///     you'd like to play
    ///     - token: JSON Web Token containing signed playback
    ///     claims
    ///     - customDomain: custom playback domain, custom domains
    ///     need to be configured as described [here](https://docs.mux.com/guides/video/use-a-custom-domain-for-streaming#use-your-own-domain-for-delivering-videos-and-images) first
    convenience init(
        signedPlaybackID: String,
        token: String,
        customDomain: URL
    ) {
        var components = URLComponents(
            url: customDomain,
            resolvingAgainstBaseURL: false
        )
        components?.path = "/\(signedPlaybackID).m3u8"
        components?.queryItems = [
            URLQueryItem(
                name: "token",
                value: token
            )
        ]

        guard let playbackURL = components?.url else {
            preconditionFailure("Invalid playback URL components")
        }

        self.init(url: playbackURL)
    }
}
