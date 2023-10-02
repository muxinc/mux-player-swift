//
//  Monitor.swift
//

import AVFoundation
import AVKit
import Foundation

import MUXSDKStats

class Monitor {

    struct MonitoredPlayer {
        var name: String
        var binding: MUXSDKPlayerBinding
    }

    static let shared = Monitor()

    var bindings: [ObjectIdentifier: MonitoredPlayer] = [:]

    func setupMonitoring(
        playerViewController: AVPlayerViewController,
        options: MonitoringOptions
    ) {

        let monitoredPlayer: MonitoredPlayer

        if let customerData = options.customerData {

            let binding = MUXSDKStats.monitorAVPlayerViewController(
                playerViewController,
                withPlayerName: options.playerName,
                customerData: customerData
            )

            monitoredPlayer = MonitoredPlayer(
                name: options.playerName,
                binding: binding!
            )

        } else {
            let customerPlayerData = MUXSDKCustomerPlayerData()

            let customerData = MUXSDKCustomerData()
            customerData.customerPlayerData = customerPlayerData

            let binding = MUXSDKStats.monitorAVPlayerViewController(
                playerViewController,
                withPlayerName: options.playerName,
                customerData: customerData
            )

            monitoredPlayer = MonitoredPlayer(
                name: options.playerName,
                binding: binding!
            )
        }

        let objectIdentifier = ObjectIdentifier(playerViewController)

        bindings[objectIdentifier] = monitoredPlayer
    }

    func tearDownMonitoring(playerViewController: AVPlayerViewController) {

        let objectIdentifier = ObjectIdentifier(playerViewController)

        guard let playerName = bindings[objectIdentifier]?.name else { return }

        MUXSDKStats.destroyPlayer(playerName)
    }
}
