//
//  AVPlayerItem+Mux.swift
//

import AVFoundation
import Foundation

internal enum PlaybackURLConstants {
    static let reverseProxyScheme = "http"

    static let reverseProxyHost = "127.0.0.1"

    static let reverseProxyPort = Int(1234)
}

internal extension URLComponents {
    init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        self.init()
        self.scheme = "https"

        if let customDomain = playbackOptions.customDomain {
            self.host = "stream.\(customDomain)"
        } else {
            self.host = "stream.mux.com"
        }

        self.path = "/\(playbackID).m3u8"

        if case PlaybackOptions.PlaybackPolicy.public(
            let publicPlaybackOptions
        ) = playbackOptions.playbackPolicy {
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

            self.queryItems = queryItems
        } else if case PlaybackOptions.PlaybackPolicy.signed(let signedPlaybackOptions) = playbackOptions.playbackPolicy {

            var queryItems: [URLQueryItem] = []

            queryItems.append(
                URLQueryItem(
                    name: "token",
                    value: signedPlaybackOptions.playbackToken
                )
            )

            self.queryItems = queryItems

        }

        let isReverseProxyEnabled = playbackOptions.enableSmartCache

        if isReverseProxyEnabled {
            // TODO: clean up
            self.queryItems = (self.queryItems ?? []) + [
                URLQueryItem(
                    name: "__hls_origin_url",
                    value: self.url!.absoluteString
                )
            ]

            // TODO: currently enables reverse proxying unless caching is disabled
            self.scheme = PlaybackURLConstants.reverseProxyScheme
            self.host = PlaybackURLConstants.reverseProxyHost
            self.port = PlaybackURLConstants.reverseProxyPort
        }

    }
}

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

    }

    let isReverseProxyEnabled = playbackOptions.enableSmartCache

    if isReverseProxyEnabled {
        // TODO: clean up
        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(
                name: "__hls_origin_url",
                value: components.url!.absoluteString
            )
        ]

        // TODO: currently enables reverse proxying unless caching is disabled
        components.scheme = PlaybackURLConstants.reverseProxyScheme
        components.host = PlaybackURLConstants.reverseProxyHost
        components.port = PlaybackURLConstants.reverseProxyPort
    }

    guard let playbackURL = components.url else {
        preconditionFailure("Invalid playback URL components")
    }

    return playbackURL
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
        
        guard let playbackURL = URLComponents(
            playbackID: playbackID,
            playbackOptions: playbackOptions
        ).url else {
            preconditionFailure("Invalid playback URL components")
        }

        self.init(url: playbackURL)
    }
}
