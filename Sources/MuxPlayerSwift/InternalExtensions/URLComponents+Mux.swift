//
//  URLComponents+Mux.swift
//

import Foundation

internal extension URLComponents {

    // MARK: - Playback URL Construction

    init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        self.init()
        self.scheme = "https"

        self.host = "stream.\(playbackOptions.rootDomain())"
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

        } else if case PlaybackOptions.PlaybackPolicy.drm(let drmPlaybackOptions) = playbackOptions.playbackPolicy {

            var queryItems: [URLQueryItem] = []

            queryItems.append(
                URLQueryItem(
                    name: "token",
                    value: drmPlaybackOptions.playbackToken
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

    // MARK: - License URL Construction
    
    // Generates an authenticated URL for retrieving a FairPlay
    // content key context (CKC). Generically referred to in
    // the Mux API as a license.
    init(
        playbackID: String,
        drmToken: String,
        licenseHostSuffix: String
    ) {
        self.init()
        self.scheme = "https"

        self.host = "license.\(licenseHostSuffix)"
        self.path = "/license/fairplay/\(playbackID)"

        var queryItems: [URLQueryItem] = []

        queryItems.append(
            URLQueryItem(
                name: "token",
                value: drmToken
            )
        )

        self.queryItems = queryItems
    }

    // Generates an authenticated URL for retrieving a FairPlay
    // application certificate.
    init(
        playbackID: String,
        drmToken: String,
        applicationCertificateHostSuffix: String
    ) {
        self.init()
        self.scheme = "https"

        self.host = "license.\(applicationCertificateHostSuffix)"
        self.path = "/appcert/fairplay/\(playbackID)"

        var queryItems: [URLQueryItem] = []

        queryItems.append(
            URLQueryItem(
                name: "token",
                value: drmToken
            )
        )

        self.queryItems = queryItems
    }
}
