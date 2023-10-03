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

            let customerData = MUXSDKCustomerData()

            if !options.environmentKey.isEmpty {
                let customerPlayerData = MUXSDKCustomerPlayerData()
                customerPlayerData.environmentKey = options.environmentKey

                customerData.customerPlayerData = customerPlayerData
            }

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

        let playerData = MUXSDKPlayerData()
        playerData.playerSoftwareVersion = SemanticVersion.versionString
        playerData.playerSoftwareName = "MuxAVPlayerViewController"

        let playbackEvent = MUXSDKPlaybackEvent()
        playbackEvent.playerData = playerData

        MUXSDKCore.dispatchEvent(
            playbackEvent,
            forPlayer: options.playerName
        )

        let objectIdentifier = ObjectIdentifier(playerViewController)

        bindings[objectIdentifier] = monitoredPlayer
    }

    func tearDownMonitoring(playerViewController: AVPlayerViewController) {

        let objectIdentifier = ObjectIdentifier(playerViewController)

        guard let playerName = bindings[objectIdentifier]?.name else { return }

        MUXSDKStats.destroyPlayer(playerName)
    }
}
