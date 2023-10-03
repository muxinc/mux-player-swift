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

        Monitor.shared.setupMonitoring(
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

        Monitor.shared.setupMonitoring(
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

        Monitor.shared.setupMonitoring(
            playerLayer: self,
            options: monitoringOptions
        )
    }

    /// Stops monitoring the player
    public func stopMonitoring() {
        Monitor.shared.tearDownMonitoring(playerLayer: self)
    }
    
}
