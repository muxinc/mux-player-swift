//
//  AVPlayerViewController+Mux.swift
//

import AVKit
import Foundation

extension AVPlayerViewController {

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameter playbackID: playback ID of the Mux
    /// Asset you'd like to play
    public convenience init(playbackID: String) {
        self.init()

        let playerItem = AVPlayerItem(playbackID: playbackID)

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        let monitoringOptions = MonitoringOptions(
            playbackID: playbackID
        )

        PlayerSDK.shared.registerPlayerViewController(
            playerViewController: self,
            monitoringOptions: monitoringOptions,
            playbackID: playbackID
        )
    }

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    public convenience init(
        playbackID: String,
        monitoringOptions: MonitoringOptions
    ) {
        self.init()

        let playerItem = AVPlayerItem(playbackID: playbackID)

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        PlayerSDK.shared.registerPlayerViewController(
            playerViewController: self,
            monitoringOptions: monitoringOptions,
            playbackID: playbackID
        )
    }

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    public convenience init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        self.init()

        let playerItem = AVPlayerItem(
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )
   
        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        let monitoringOptions = MonitoringOptions(
            playbackID: playbackID
        )

        if case PlaybackOptions.PlaybackPolicy.drm(_) = playbackOptions.playbackPolicy {
            PlayerSDK.shared.registerPlayerViewController(
                playerViewController: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: true
            )
        } else {
            PlayerSDK.shared.registerPlayerViewController(
                playerViewController: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: false
            )
        }
    }

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    public convenience init(
        playbackID: String,
        playbackOptions: PlaybackOptions,
        monitoringOptions: MonitoringOptions
    ) {
        self.init()

        let playerItem = AVPlayerItem(
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        if case PlaybackOptions.PlaybackPolicy.drm(_) = playbackOptions.playbackPolicy {
            PlayerSDK.shared.registerPlayerViewController(
                playerViewController: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: true
            )
        } else {
            PlayerSDK.shared.registerPlayerViewController(
                playerViewController: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: false
            )
        }
    }

    /// Stops monitoring the player
    public func stopMonitoring() {
        PlayerSDK.shared.monitor.tearDownMonitoring(playerViewController: self)
    }


    /// Prepares an already instantiated AVPlayerViewController
    /// for playback.
    ///
    /// If AVPlayerViewController doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerViewController player property. If
    /// the AVPlayerViewController already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    public func prepare(
        playbackID: String
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID
            ),
            playbackID: playbackID,
            monitoringOptions: MonitoringOptions(
                playbackID: playbackID
            )
        )
    }


    /// Prepares an already instantiated AVPlayerViewController
    /// for playback.
    ///
    /// If AVPlayerViewController doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerViewController player property. If
    /// the AVPlayerViewController already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    public func prepare(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID,
                playbackOptions: playbackOptions
            ),
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            monitoringOptions: MonitoringOptions(
                playbackID: playbackID
            )
        )
    }


    /// Prepares an already instantiated AVPlayerViewController
    /// for playback.
    ///
    /// If AVPlayerViewController doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerViewController player property. If
    /// the AVPlayerViewController already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    public func prepare(
        playbackID: String,
        monitoringOptions: MonitoringOptions
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID
            ),
            playbackID: playbackID,
            monitoringOptions: monitoringOptions
        )
    }


    /// Prepares an already instantiated AVPlayerViewController
    /// for playback.
    ///
    /// If AVPlayerViewController doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerViewController player property. If
    /// the AVPlayerViewController already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    public func prepare(
        playbackID: String,
        playbackOptions: PlaybackOptions,
        monitoringOptions: MonitoringOptions
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID,
                playbackOptions: playbackOptions
            ),
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            monitoringOptions: monitoringOptions
        )
    }

    internal func prepare(
        playerItem: AVPlayerItem,
        playbackID: String,
        playbackOptions: PlaybackOptions = PlaybackOptions(),
        monitoringOptions: MonitoringOptions,
        playerSDK: PlayerSDK = .shared
    ) {
        if let player {
            player.replaceCurrentItem(
                with: playerItem
            )
        } else {
            player = AVPlayer(
                playerItem: playerItem
            )
        }

        let usingDRM: Bool

        if case PlaybackOptions.PlaybackPolicy.drm(_) = playbackOptions.playbackPolicy {
            usingDRM = true
        } else {
            usingDRM = false
        }

        playerSDK.registerPlayerViewController(
            playerViewController: self,
            monitoringOptions: monitoringOptions,
            playbackID: playbackID,
            requiresReverseProxying: playbackOptions.enableSmartCache,
            usingDRM: usingDRM
        )
    }
}
