//
//  TestPlayerObservationContext.swift
//

import Foundation

import MUXSDKStats

@testable import MuxPlayerSwift

class TestPlayerObservationContext: PlayerObservationContext {

    struct MonitorCall {
        // AVPlayerViewController or AVPlayerLayer or AVPlayer
        // Only included to validate pointer equality, for
        // which NSObject suffices
        let player: NSObject
        let playerName: String
        let customerData: MUXSDKCustomerData
        let automaticErrorTracking: Bool
    }

    var monitorCalls: [MonitorCall] = []

    override func monitorAVPlayerViewController(
        _ player: AVPlayerViewController,
        withPlayerName name: String,
        customerData: MUXSDKCustomerData,
        automaticErrorTracking: Bool
    ) -> MUXSDKPlayerBinding? {

        monitorCalls.append(
            MonitorCall(
                player: player,
                playerName: name,
                customerData: customerData,
                automaticErrorTracking: automaticErrorTracking
            )
        )

        // In its current state this test class is only
        // useful for validating Mux Data inputs.
        //
        // This needs to return a non-nil value in order to
        // validate side effects in this SDK.
        return nil
    }

    override func monitorAVPlayerLayer(
        _ player: AVPlayerLayer,
        withPlayerName name: String,
        customerData: MUXSDKCustomerData,
        automaticErrorTracking: Bool
    ) -> MUXSDKPlayerBinding? {

        monitorCalls.append(
            MonitorCall(
                player: player,
                playerName: name,
                customerData: customerData,
                automaticErrorTracking: automaticErrorTracking
            )
        )

        // In its current state this test class is only
        // useful for validating Mux Data inputs.
        //
        // This needs to return a non-nil value in order to
        // validate side effects in this SDK.
        return nil
    }

    override func destroyPlayer(
        _ name: String
    ) {

    }
}
