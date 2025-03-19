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

// TODO: not a public API. this extension has been modified. It has been hackily refactored to fit your proof-of-concept
public extension AVPlayerItem {

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
        guard let playbackURL = URLComponents(
           playbackID: playbackID,
           playbackOptions: PlaybackOptions()
       ).url else {
           preconditionFailure("Invalid playback URL components")
       }
        
        self.init(
            playbackURL: playbackURL,
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(),
            playerSDK: .shared
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

        self.init(
            playbackURL: playbackURL,
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            playerSDK: .shared
        )
    }
    
    //TODO: something to make sure the item is prepared? only if this becomes the real api
    convenience init(
        url: URL,
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        self.init(
            playbackURL: url,
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            playerSDK: .shared
        )
    }
    
    internal convenience init(
        playbackURL: URL,
        playbackID: String,
        playbackOptions: PlaybackOptions,
        playerSDK: PlayerSDK
    ) {
        // Create a new `AVAsset` that has been prepared
        // for playback
       
        let asset = AVURLAsset(
            url: playbackURL
        )

        self.init(
            asset: asset
        )

        playerSDK.registerPlayerItem(
            self,
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )
    }
}

public extension AVPlayerItem {

    // Extracts Mux playback ID from remote AVAsset, if possible
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
