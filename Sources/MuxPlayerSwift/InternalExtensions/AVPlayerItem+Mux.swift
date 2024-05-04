//
//  AVPlayerItem+Mux.swift
//

import AVFoundation
import Foundation

internal extension URL {
    static func make(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) -> Self {
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

            if publicPlaybackOptions.minimumResolutionTier != .default {
                queryItems.append(
                    URLQueryItem(
                        name: "min_resolution",
                        value: publicPlaybackOptions.minimumResolutionTier.queryValue
                    )
                )
            }

            if publicPlaybackOptions.renditionOrder != .default {
                queryItems.append(
                    URLQueryItem(
                        name: "rendition_order",
                        value: publicPlaybackOptions.renditionOrder.queryValue
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

        } else if case PlaybackOptions.PlaybackPolicy.drm(let drmPlaybackOptions) = playbackOptions.playbackPolicy {

            var queryItems: [URLQueryItem] = []

            queryItems.append(
                URLQueryItem(
                    name: "token",
                    value: drmPlaybackOptions.playbackToken
                )
            )

            components.queryItems = queryItems

        }

        guard let playbackURL = components.url else {
            preconditionFailure("Invalid playback URL components")
        }

        return playbackURL
    }
}


internal extension AVPlayerItem {

    // Initializes a player item with a playback URL that
    // references your Mux Video at the supplied playback ID.
    // The playback ID must be public.
    //
    // This initializer uses https://stream.mux.com as the
    // base URL. Use a different initializer if using a custom
    // playback URL.
    //
    // - Parameter playbackID: playback ID of the Mux Asset
    // you'd like to play
    convenience init(playbackID: String) {
        self.init(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions()
        )
    }

    // Initializes a player item with a playback URL that
    // references your Mux Video at the supplied playback ID.
    // The playback ID must be public.
    //
    // - Parameters:
    //   - playbackID: playback ID of the Mux Asset
    //   you'd like to play
    convenience init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {

        // Create a new `AVAsset` that has been prepared
        // for playback
        let asset = AVURLAsset(
            url: URL.make(
                playbackID: playbackID,
                playbackOptions: playbackOptions
            )
        )

        self.init(
            asset: asset
        )

        PlayerSDK.shared.registerPlayerItem(
            self,
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )
    }
}
