//
//  MonitoringOptions.swift
//

import Foundation

import MuxCore

/// Options to customize monitoring data reported by Mux
public struct MonitoringOptions {

    /// Environment key associated with the monitoring data
    var environmentKey: String?

    /// Identifies the player name
    public var playerName: String

    var customerData: MUXSDKCustomerData?

    /// Initializes options to customize monitoring by Mux
    /// - Parameter playbackID: helps identify your Data environment,
    public init(playbackID: String) {
        self.environmentKey = nil
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

    /// Initializes options to customize monitoring by Mux
    /// using the existing `MUXSDKStats` customer data override.
    /// - Parameters:
    ///   - customerData: passed through as-is when initializing
    ///   Mux Data monitoring
    public init(
        customerData: MUXSDKCustomerData,
        playerName: String
    ) {
        self.customerData = customerData
        self.environmentKey = nil
        self.playerName = playerName
    }
}
