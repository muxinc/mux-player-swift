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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
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

        PlayerSDK.shared.monitor.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
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
            playerViewController: self,
            options: monitoringOptions
        )
    }

    /// Stops monitoring the player
    public func stopMonitoring() {
        PlayerSDK.shared.monitor.tearDownMonitoring(playerViewController: self)
    }

}
