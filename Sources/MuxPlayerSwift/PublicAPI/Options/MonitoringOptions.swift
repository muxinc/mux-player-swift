//
//  MonitoringOptions.swift
//

import Foundation

import MuxCore

/// Options to customize monitoring data reported by Mux
public struct MonitoringOptions {

    // Environment key associated with the monitoring data
    var environmentKey: String?

    /// Identifies the player name used when setting up
    /// monitoring with Mux Data
    public var playerName: String

    /// Track player errors automatically using Mux Data.
    /// If you disable automatic error tracking, you can track errors using methods on ``MUXSDKStats``
    public var automaticErrorTracking: Bool
    
    var customerData: MUXSDKCustomerData?

    /// Initializes options to customize monitoring by Mux
    /// - Parameter playbackID: helps identify your Data environment,
    /// - Parameter automaticErrorTracking: Track errors automatically in Mux Data. Default is true
    public init(playbackID: String, automaticErrorTracking: Bool = true) {
        self.environmentKey = nil
        let uniquePlayerName = "\(playbackID)-\(UUID().uuidString)"
        self.playerName = uniquePlayerName
        self.automaticErrorTracking = automaticErrorTracking
    }

    /// Initializes options to customize monitoring by Mux
    /// - Parameters:
    ///   - environmentKey: identifies your Data environment,
    ///   generated in the Dashboard
    ///   - playerName: identifier of the player
    ///   - automaticErrorTracking: Track errors in automatically in Mux Data. Default is true
    public init(environmentKey: String, playerName: String, automaticErrorTracking: Bool = true) {
        self.environmentKey = environmentKey
        self.playerName = playerName
        self.automaticErrorTracking = automaticErrorTracking
    }

    /// Initializes options to customize monitoring by Mux
    /// using the existing `MUXSDKStats` customer data override.
    /// - Parameters:
    ///   - customerData: passed through as-is when initializing
    ///   Mux Data monitoring
    ///   - playerName: identifier of the player
    ///   - automaticErrorTracking: Track errors automatically in Mux Data. Default is true
    public init(
        customerData: MUXSDKCustomerData,
        playerName: String,
        automaticErrorTracking: Bool = true
    ) {
        self.customerData = customerData
        self.environmentKey = nil
        self.playerName = playerName
        self.automaticErrorTracking = automaticErrorTracking
    }
}
