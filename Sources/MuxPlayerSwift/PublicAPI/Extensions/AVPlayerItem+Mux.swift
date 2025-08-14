//
//  File.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 8/14/25.
//

import Foundation
import AVKit

public extension AVPlayerItem {
    
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
    ///
    /// > important: To use Mux Data, you must still  use ``AVPlayerViewController.prepare(playbackID:)``, ``AVPlayerLayer.prepare(playbackID:)`` or a realted method
    ///
    /// - SeeAlso:
    ///   -  ``AVPlayerViewController.init(playbackID:)``
    ///   -  ``AVPlayerViewController.init(playbackID:monitoringOptions:)``
    ///   -  ``AVPlayerViewController.init(playbackID:playbackOptions:)``
    ///   -  ``AVPlayerViewController.init(playbackID:playbackOptions:monitoringOptions:)``
    ///   -  ``AVPlayerLayer.init(playbackID:)``
    ///   -  ``AVPlayerLayer.init(playbackID:monitoringOptions:)``
    ///   -  ``AVPlayerLayer.init(playbackID:playbackOptions:)``
    ///   -  ``AVPlayerLayer.init(playbackID:playbackOptions:monitoringOptions:)``
    convenience init(playbackID: String) {
        self.init(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(),
            playerSDK: .shared
        )
    }

    /// Initializes a player item with a playback URL that
    /// references your Mux Video at the supplied playback ID.
    /// The playback ID must be public.
    ///
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: Options for how to play your asset
    /// > important: To use Mux Data, you must still  use ``AVPlayerViewController.prepare(playbackID:)``, ``AVPlayerLayer.prepare(playbackID:)`` or a realted method
    ///
    /// - SeeAlso:
    ///   -  ``AVPlayerViewController.init(playbackID:)``
    ///   -  ``AVPlayerViewController.init(playbackID:monitoringOptions:)``
    ///   -  ``AVPlayerViewController.init(playbackID:playbackOptions:)``
    ///   -  ``AVPlayerViewController.init(playbackID:playbackOptions:monitoringOptions:)``
    ///   -  ``AVPlayerViewController.prepare(playbackID:playbackOptions:monitoringOptions:)``
    ///   -  ``AVPlayerLayer.init(playbackID:)``
    ///   -  ``AVPlayerLayer.init(playbackID:monitoringOptions:)``
    ///   -  ``AVPlayerLayer.init(playbackID:playbackOptions:)``
    ///   -  ``AVPlayerLayer.init(playbackID:playbackOptions:monitoringOptions:)``
    ///   -  ``AVPlayerLayer.prepare(playbackID:playbackOptions:monitoringOptions:)``
    convenience init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        self.init(
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            playerSDK: .shared
        )
    }
}

public extension AVPlayerItem {
    
    /// Extracts Mux playback ID from remote AVAsset, if possible
    var playbackID: String? {
        guard let remoteAsset = asset as? AVURLAsset else {
            return nil
        }

        guard let components = URLComponents(
            url: remoteAsset.url,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        guard let host = components.host, host.contains("stream.") else {
            return nil
        }

        guard components.path.hasSuffix(".m3u8") else {
            return nil
        }

        var path = components.path

        path.removeLast(5)

        path.removeFirst(1)

        return path
    }

}
