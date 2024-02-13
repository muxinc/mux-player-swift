//
//  Monitor.swift
//

import AVFoundation
import AVKit
import Foundation

import MuxCore
import MUXSDKStats

class Monitor {

    struct MonitoredPlayer {
        var name: String
        var binding: MUXSDKPlayerBinding
    }

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

            let customerData = MUXSDKCustomerData()
            let customerPlayerData = MUXSDKCustomerPlayerData()
            customerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
            customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerViewController"

            if let environmentKey = options.environmentKey {
                customerPlayerData.environmentKey = environmentKey
            }
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

    func setupMonitoring(
        playerLayer: AVPlayerLayer,
        options: MonitoringOptions
    ) {
        let monitoredPlayer: MonitoredPlayer

        if let customerData = options.customerData {

            let binding = MUXSDKStats.monitorAVPlayerLayer(
                playerLayer,
                withPlayerName: options.playerName,
                customerData: customerData
            )

            monitoredPlayer = MonitoredPlayer(
                name: options.playerName,
                binding: binding!
            )

        } else {

            let customerData = MUXSDKCustomerData()
            let customerPlayerData = MUXSDKCustomerPlayerData()
            customerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
            customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerLayer"

            if let environmentKey = options.environmentKey {
                customerPlayerData.environmentKey = environmentKey
            }
            customerData.customerPlayerData = customerPlayerData

            let binding = MUXSDKStats.monitorAVPlayerLayer(
                playerLayer,
                withPlayerName: options.playerName,
                customerData: customerData
            )

            monitoredPlayer = MonitoredPlayer(
                name: options.playerName,
                binding: binding!
            )
        }

        let objectIdentifier = ObjectIdentifier(playerLayer)

        bindings[objectIdentifier] = monitoredPlayer
    }

    func tearDownMonitoring(playerViewController: AVPlayerViewController) {

        let objectIdentifier = ObjectIdentifier(playerViewController)

        guard let playerName = bindings[objectIdentifier]?.name else { return }

        MUXSDKStats.destroyPlayer(playerName)

        bindings.removeValue(forKey: objectIdentifier)
    }

    func tearDownMonitoring(playerLayer: AVPlayerLayer) {

        let objectIdentifier = ObjectIdentifier(playerLayer)

        guard let playerName = bindings[objectIdentifier]?.name else { return }

        MUXSDKStats.destroyPlayer(playerName)

        bindings.removeValue(forKey: objectIdentifier)
    }
}
