//
//  Monitor.swift
//

import AVFoundation
import AVKit
import Foundation

import MuxCore
import MUXSDKStats

class Monitor: ErrorDispatcher {

    struct MonitoredPlayer {
        var name: String
        var binding: MUXSDKPlayerBinding
    }

    var bindings: [ObjectIdentifier: MonitoredPlayer] = [:]

    func setupMonitoring(
        playerViewController: AVPlayerViewController,
        playbackID: String,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {

        let customerData: MUXSDKCustomerData

        if let externallySpecifiedCustomerData = options.customerData {

            let modifiedCustomerData = MUXSDKCustomerData()

            if let customerVideoData = externallySpecifiedCustomerData.customerVideoData {
                let customerVideoDataCopy = MUXSDKCustomerVideoData()
                customerVideoDataCopy.setQuery(customerVideoData.toQuery())
                modifiedCustomerData.customerVideoData = customerVideoData
            }

            if let customerViewData = externallySpecifiedCustomerData.customerViewData {
                let customerViewDataCopy = MUXSDKCustomerViewData()
                customerViewDataCopy.setQuery(customerViewData.toQuery())
                modifiedCustomerData.customerViewData = customerViewData
            }

            if let customerViewerData = externallySpecifiedCustomerData.customerViewerData {
                let customerViewerDataCopy = MUXSDKCustomerViewerData()
                customerViewerDataCopy.viewerApplicationName = customerViewerData.viewerApplicationName
                customerViewerDataCopy.viewerDeviceCategory = customerViewerData.viewerDeviceCategory
                customerViewerDataCopy.viewerDeviceManufacturer = customerViewerData.viewerDeviceManufacturer
                customerViewerDataCopy.viewerDeviceModel = customerViewerData.viewerDeviceModel
                customerViewerDataCopy.viewerOsFamily = customerViewerData.viewerOsFamily
                customerViewerDataCopy.viewerOsVersion = customerViewerData.viewerOsVersion
                modifiedCustomerData.customerViewerData = customerViewerData
            }

            if let customerPlayerData = externallySpecifiedCustomerData.customerPlayerData {
                let customerPlayerDataCopy = MUXSDKCustomerPlayerData()
                customerPlayerDataCopy.setQuery(
                    customerPlayerData.toQuery()
                )
                customerPlayerDataCopy.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerDataCopy.playerSoftwareName = "MuxPlayerSwiftAVPlayerViewController"
                modifiedCustomerData.customerPlayerData = customerPlayerDataCopy
            } else {
                let customerPlayerData = MUXSDKCustomerPlayerData()
                customerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerViewController"
                modifiedCustomerData.customerPlayerData = customerPlayerData
            }

            customerData = modifiedCustomerData
            
        } else {

            customerData = MUXSDKCustomerData()
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
        }

        let shouldTrackErrorsAutomatically = !usingDRM

        let binding = MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: options.playerName,
            customerData: customerData,
            automaticErrorTracking: shouldTrackErrorsAutomatically
        )

        let monitoredPlayer = MonitoredPlayer(
            name: options.playerName,
            binding: binding!
        )

        let objectIdentifier = ObjectIdentifier(playerViewController)

        bindings[objectIdentifier] = monitoredPlayer
    }

    func setupMonitoring(
        playerLayer: AVPlayerLayer,
        playbackID: String,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        let customerData: MUXSDKCustomerData

        if let externallySpecifiedCustomerData = options.customerData {

            let modifiedCustomerData = MUXSDKCustomerData()

            if let customerPlayerData = externallySpecifiedCustomerData.customerPlayerData {
                let customerPlayerDataCopy = MUXSDKCustomerPlayerData()
                customerPlayerDataCopy.setQuery(
                    customerPlayerData.toQuery()
                )
                customerPlayerDataCopy.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerLayer"
                modifiedCustomerData.customerPlayerData = customerPlayerDataCopy
            } else {
                let customerPlayerData = MUXSDKCustomerPlayerData()
                customerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerLayer"
                modifiedCustomerData.customerPlayerData = customerPlayerData
            }

            customerData = modifiedCustomerData

        } else {

            customerData = MUXSDKCustomerData()
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
        }

        let shouldTrackErrorsAutomatically = !usingDRM

        let binding = MUXSDKStats.monitorAVPlayerLayer(
            playerLayer,
            withPlayerName: options.playerName,
            customerData: customerData,
            automaticErrorTracking: shouldTrackErrorsAutomatically
        )

        let monitoredPlayer = MonitoredPlayer(
            name: options.playerName,
            binding: binding!
        )

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

    // MARK: - Player Item Tracking

    func handleUpdatedCurrentPlayerItem(
        _ playerItem: AVPlayerItem?,
        for player: AVPlayer
    ) {

    }

    // MARK: - Error Dispatch

    func dispatchApplicationCertificateRequestError(
        error: FairPlaySessionError,
        playbackID: String
    ) {

    }

    func dispatchLicenseRequestError(
        error: FairPlaySessionError,
        playbackID: String
    ) {

    }
}
