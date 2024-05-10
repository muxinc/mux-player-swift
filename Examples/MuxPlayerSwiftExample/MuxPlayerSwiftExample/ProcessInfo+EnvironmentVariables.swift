//
//  ProcessInfo+EnvironmentVariables.swift
//  MuxPlayerSwiftExample
//

import Foundation

// Configure these as environment variables in
// application scheme
extension ProcessInfo {
    var environmentKey: String? {
        guard let value = environment["ENV_KEY"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

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

    var customDomain: String? {
        guard let value = environment["CUSTOM_DOMAIN"],
                !value.isEmpty else {
            return nil
        }

        return value
    }
}
