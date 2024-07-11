//
//  ProcessInfo+EnvironmentVariables.swift
//  MuxPlayerSwiftExample
//

import Foundation

// Configure these as environment variables in
// application scheme
extension ProcessInfo {

// MARK: Mux Data Environment Key
    var environmentKey: String? {
        guard let value = environment["ENV_KEY"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

// MARK: Mux Video Playback Constants

    var playbackID: String? {
        guard let value = environment["PLAYBACK_ID"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var playbackToken: String? {
        guard let value = environment["PLAYBACK_TOKEN"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var drmToken: String? {
        guard let value = environment["DRM_TOKEN"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var secondaryPlaybackID: String? {
        guard let value = environment["SECONDARY_PLAYBACK_ID"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var secondaryPlaybackToken: String? {
        guard let value = environment["SECONDARY_PLAYBACK_TOKEN"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var secondaryDRMToken: String? {
        guard let value = environment["SECONDARY_DRM_TOKEN"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

// MARK: Mux Video Custom Playback Domain


    /// Once Mux has provisioned your Custom Domain, set the
    /// `CUSTOM_DOMAIN` environment variable and Mux Player
    /// Swift will pass that on to `AVPlayer` to use when
    /// streaming video.
    ///
    /// Mux Player Swift automatically prepends the `stream`
    /// subdomain for you. This means that if you set
    /// `media.example.com` as `CUSTOM_DOMAIN` then `AVPlayer`
    /// will use `stream.media.example.com` when requesting
    /// media. [See here for more details](https://www.mux.com/blog/introducing-custom-domains).
    var customDomain: String? {
        guard let value = environment["CUSTOM_DOMAIN"],
                !value.isEmpty else {
            return nil
        }

        return value
    }
}
