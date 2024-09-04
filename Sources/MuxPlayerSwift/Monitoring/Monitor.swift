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
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {

        let monitoredPlayer: MonitoredPlayer

        if let customerData = options.customerData {

            let customerDataCopy = MUXSDKCustomerData()

            if let customerVideoData = customerData.customerVideoData {
                let customerVideoDataCopy = MUXSDKCustomerVideoData()
                customerVideoDataCopy.setQuery(customerVideoData.toQuery())
                customerDataCopy.customerVideoData = customerVideoData
            }

            if let customerViewData = customerData.customerViewData {
                let customerViewDataCopy = MUXSDKCustomerViewData()
                customerViewDataCopy.setQuery(customerViewData.toQuery())
                customerDataCopy.customerViewData = customerViewData
            }

            if let customerViewerData = customerData.customerViewerData {
                let customerViewerDataCopy = MUXSDKCustomerViewerData()
                customerViewerDataCopy.viewerApplicationName = customerViewerData.viewerApplicationName
                customerViewerDataCopy.viewerDeviceCategory = customerViewerData.viewerDeviceCategory
                customerViewerDataCopy.viewerDeviceManufacturer = customerViewerData.viewerDeviceManufacturer
                customerViewerDataCopy.viewerDeviceModel = customerViewerData.viewerDeviceModel
                customerViewerDataCopy.viewerOsFamily = customerViewerData.viewerOsFamily
                customerViewerDataCopy.viewerOsVersion = customerViewerData.viewerOsVersion
                customerDataCopy.customerViewerData = customerViewerData
            }

            if let customerPlayerData = customerData.customerPlayerData {
                let customerPlayerDataCopy = MUXSDKCustomerPlayerData()
                customerPlayerDataCopy.setQuery(
                    customerPlayerData.toQuery()
                )
                customerPlayerDataCopy.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerDataCopy.playerSoftwareName = "MuxPlayerSwiftAVPlayerViewController"
                customerDataCopy.customerPlayerData = customerPlayerDataCopy
            } else {
                let customerPlayerData = MUXSDKCustomerPlayerData()
                customerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerViewController"
                customerDataCopy.customerPlayerData = customerPlayerData
            }

            let binding = MUXSDKStats.monitorAVPlayerViewController(
                playerViewController,
                withPlayerName: options.playerName,
                customerData: customerDataCopy
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

            if usingDRM {
                let customerViewData = MUXSDKCustomerViewData()
                customerViewData.viewDrmType = "fairplay"
                customerData.customerViewData = customerViewData
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

        let objectIdentifier = ObjectIdentifier(playerViewController)

        bindings[objectIdentifier] = monitoredPlayer
    }

    func setupMonitoring(
        playerLayer: AVPlayerLayer,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        let monitoredPlayer: MonitoredPlayer

        if let customerData = options.customerData {

            let customerDataCopy = MUXSDKCustomerData()

            if let customerPlayerData = customerData.customerPlayerData {
                let customerPlayerDataCopy = MUXSDKCustomerPlayerData()
                customerPlayerDataCopy.setQuery(
                    customerPlayerData.toQuery()
                )
                customerPlayerDataCopy.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerLayer"
                customerDataCopy.customerPlayerData = customerPlayerDataCopy
            } else {
                let customerPlayerData = MUXSDKCustomerPlayerData()
                customerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerLayer"
                customerDataCopy.customerPlayerData = customerPlayerData
            }

            let binding = MUXSDKStats.monitorAVPlayerLayer(
                playerLayer,
                withPlayerName: options.playerName,
                customerData: customerDataCopy
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

            if usingDRM {
                let customerViewData = MUXSDKCustomerViewData()
                customerViewData.viewDrmType = "fairplay"
                customerData.customerViewData = customerViewData
            }

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
