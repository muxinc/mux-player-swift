//
//  AVPlayerLayer+Mux.swift
//

import AVFoundation
import Foundation

public extension AVPlayerLayer {
    
    /// If this AVPlayerLayer is being monitored by mux data, this is the `playerName` to use with `MUXSDKStats`
    var muxDataName: String? {
        let selfIdentifier = ObjectIdentifier(self)
        return PlayerSDK.shared.monitor.bindings[selfIdentifier]?.name
    }
    
    /// Initializes an AVPlayerLayer that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameter playbackID: playback ID of the Mux
    /// Asset you'd like to play
    convenience init(playbackID: String) {
        self.init()

        let playerItem = AVPlayerItem(
            playbackID: playbackID
        )

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        let monitoringOptions = MonitoringOptions(
            playbackID: playbackID
        )

        PlayerSDK.shared.monitor.setupMonitoring(
            playerLayer: self,
            playbackID: playbackID,
            options: monitoringOptions
        )
    }

    /// Initializes an AVPlayerLayer that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    convenience init(
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
            PlayerSDK.shared.registerPlayerLayer(
                playerLayer: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: true
            )
        } else {
            PlayerSDK.shared.registerPlayerLayer(
                playerLayer: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: false
            )
        }
    }

    /// Initializes an AVPlayerLayer that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    convenience init(
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
            PlayerSDK.shared.registerPlayerLayer(
                playerLayer: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: true
            )
        } else {
            PlayerSDK.shared.registerPlayerLayer(
                playerLayer: self,
                monitoringOptions: monitoringOptions,
                playbackID: playbackID,
                requiresReverseProxying: playbackOptions.enableSmartCache,
                usingDRM: false
            )
        }
    }

    /// Stops monitoring the player
    func stopMonitoring() {
        PlayerSDK.shared.monitor.tearDownMonitoring(playerLayer: self)
    }
    

    /// Prepares an already instantiated AVPlayerLayer
    /// for playback.
    ///
    /// If AVPlayerLayer doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerLayer player property. If
    /// the AVPlayerLayer already holds a player,
    /// it will be configured for playback.
    ///
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    func prepare(
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

    /// Prepares an already instantiated AVPlayerLayer
    /// for playback.
    ///
    /// If AVPlayerLayer doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerLayer player property. If
    /// the AVPlayerLayer already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    func prepare(
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

    /// Prepares an already instantiated AVPlayerLayer
    /// for playback.
    ///
    /// If AVPlayerLayer doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerLayer player property. If
    /// the AVPlayerLayer already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    func prepare(
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

    /// Prepares an already instantiated AVPlayerLayer
    /// for playback.
    ///
    /// If AVPlayerLayer doesn't already hold an
    /// AVPlayer reference, this method will create one and
    /// set the AVPlayerLayer player property. If
    /// the AVPlayerLayer already holds a player,
    /// it will be configured for playback.
    /// - Parameters:
    ///   - playbackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - playbackOptions: playback-related options such
    ///   as custom domain and maximum resolution
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    func prepare(
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

        playerSDK.registerPlayerLayer(
            playerLayer: self,
            monitoringOptions: monitoringOptions,
            playbackID: playbackID,
            requiresReverseProxying: playbackOptions.enableSmartCache,
            usingDRM: usingDRM
        )
    }
}
