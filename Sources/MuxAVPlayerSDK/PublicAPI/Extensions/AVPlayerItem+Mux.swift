//
//  AVPlayerItem+Mux.swift
//

import AVFoundation
import Foundation

extension AVPlayerItem {

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
    convenience init(publicPlaybackID: String) {
        guard let baseURL = URL(string: "https://stream.mux.com") else {
            preconditionFailure("Invalid base URL string")
        }

        var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        )
        components?.path = "/\(publicPlaybackID).m3u8"

        guard let playbackURL = components?.url else {
            preconditionFailure("Invalid playback URL components")
        }

        self.init(url: playbackURL)
    }

    /// Initializes a player item with a playback URL that
    /// references your Mux Video at the supplied playback ID.
    /// The playback ID must be public.
    ///
    /// - Parameters:
    ///   - publicPlaybackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - customDomain: custom playback domain, custom domains
    ///   need to be configured as described [here](https://docs.mux.com/guides/video/use-a-custom-domain-for-streaming#use-your-own-domain-for-delivering-videos-and-images) first
    convenience init(publicPlaybackID: String, customDomain: URL) {
        var components = URLComponents(
            url: customDomain,
            resolvingAgainstBaseURL: false
        )
        components?.path = "/\(publicPlaybackID).m3u8"

        guard let playbackURL = components?.url else {
            preconditionFailure("Invalid playback URL components")
        }

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
