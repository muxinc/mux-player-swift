//
//  AVPlayerViewController+Mux.swift
//

import AVKit
import Foundation

extension AVPlayerViewController {

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameter publicPlaybackID: playback ID of the Mux
    /// Asset you'd like to play
    public convenience init(publicPlaybackID: String) {
        self.init()

        let playerItem = AVPlayerItem(publicPlaybackID: publicPlaybackID)

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        let monitoringOptions = MonitoringOptions(playbackID: publicPlaybackID)

        Monitor.shared.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
        )
    }

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - publicPlaybackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    public convenience init(
        publicPlaybackID: String,
        monitoringOptions: MonitoringOptions
    ) {
        self.init()

        let playerItem = AVPlayerItem(publicPlaybackID: publicPlaybackID)

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        Monitor.shared.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
        )
    }

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - publicPlaybackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - customDomain: custom playback domain, custom domains
    ///   need to be configured as described [here](https://docs.mux.com/guides/video/use-a-custom-domain-for-streaming#use-your-own-domain-for-delivering-videos-and-images) first
    convenience init(publicPlaybackID: String, customDomain: URL) {
        self.init()

        let playerItem = AVPlayerItem(
            publicPlaybackID: publicPlaybackID,
            customDomain: customDomain
        )

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        let monitoringOptions = MonitoringOptions(playbackID: publicPlaybackID)

        Monitor.shared.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
        )
    }

    /// Initializes an AVPlayerViewController that's configured
    /// to play your Mux Asset as well as monitor and report
    /// back it's playback performance.
    /// - Parameters:
    ///   - publicPlaybackID: playback ID of the Mux Asset
    ///   you'd like to play
    ///   - customDomain: custom playback domain, custom
    ///   domains need to be configured as described [here](https://docs.mux.com/guides/video/use-a-custom-domain-for-streaming#use-your-own-domain-for-delivering-videos-and-images) first
    ///   - monitoringOptions: Options to customize monitoring
    ///   data reported by Mux
    convenience init(
        publicPlaybackID: String,
        customDomain: URL,
        monitoringOptions: MonitoringOptions
    ) {
        self.init()

        let playerItem = AVPlayerItem(
            publicPlaybackID: publicPlaybackID,
            customDomain: customDomain
        )

        let player = AVPlayer(playerItem: playerItem)

        self.player = player

        Monitor.shared.setupMonitoring(
            playerViewController: self,
            options: monitoringOptions
        )
    }

    /// Stops monitoring the player
    public func stopMonitoring() {
        Monitor.shared.tearDownMonitoring(playerViewController: self)
    }

}
