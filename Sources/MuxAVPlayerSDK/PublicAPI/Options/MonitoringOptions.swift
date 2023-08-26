//
//  MonitoringOptions.swift
//

import Foundation

/// Options to customize monitoring data reported by Mux
public struct MonitoringOptions {

    /// Environment key associated with the monitoring data
    public var environmentKey: String

    /// Identifies the player name
    public var playerName: String

    /// Initializes options to customize monitoring by Mux
    /// - Parameter playbackID: helps identify your Data environment,
    public init(playbackID: String) {
        /// Mux will use the same environment as the one used
        /// associated with the playback ID
        self.environmentKey = playbackID
        let uniquePlayerName = "\(playbackID)-\(UUID().uuidString)"
        self.playerName = uniquePlayerName
    }

    /// Initializes options to customize monitoring by Mux
    /// - Parameters:
    ///   - environmentKey: identifies your Data environment,
    ///   generated in the Dashboard
    ///   - playerName: identifier of the player
    public init(environmentKey: String, playerName: String) {
        self.environmentKey = environmentKey
        self.playerName = playerName
    }
}
