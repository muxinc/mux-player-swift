//
//  AVPlayerLayer+Mux.swift
//

import AVFoundation
import Foundation

extension AVPlayerLayer {

    /// Initializes an AVPlayerLayer that's configured
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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerLayer: self,
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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerLayer: self,
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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerLayer: self,
            options: monitoringOptions
        )
    }

    /// Stops monitoring the player
    public func stopMonitoring() {
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
    public func prepare(
        playbackID: String
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID
            ),
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
    public func prepare(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID,
                playbackOptions: playbackOptions
            ),
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
    public func prepare(
        playbackID: String,
        monitoringOptions: MonitoringOptions
    ) {
        prepare(
            playerItem: AVPlayerItem(
                playbackID: playbackID
            ),
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
            monitoringOptions: monitoringOptions
        )
    }

    internal func prepare(
        playerItem: AVPlayerItem,
        monitoringOptions: MonitoringOptions
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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerLayer: self,
            options: monitoringOptions
        )
    }
}
