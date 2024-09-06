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
        var playerIdentifier: ObjectIdentifier
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

        guard let binding else {
            return
        }

        let monitoredPlayer = MonitoredPlayer(
            name: options.playerName,
            binding: binding,
            playerIdentifier: ObjectIdentifier(playerViewController.player!)
        )

        let objectIdentifier = ObjectIdentifier(playerViewController)

        bindings[objectIdentifier] = monitoredPlayer

        if let player = playerViewController.player {
            // TODO: Add a better way to protect against
            // dual registrations for the same player
            keyValueObservation.unregister(
                player
            )

            keyValueObservation.register(
                player,
                for: \.error,
                options: [.new, .old]
            ) { player, change in
                if let error = (change.newValue ?? nil) as? NSError,
                    ((change.oldValue ?? nil) == nil) {
                    binding.dispatchError(
                        "\(error.code)",
                        withMessage: error.localizedFailureReason
                    )
                }
            }
        }
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

        guard let binding else {
            return
        }

        let monitoredPlayer = MonitoredPlayer(
            name: options.playerName,
            binding: binding,
            playerIdentifier: ObjectIdentifier(playerLayer.player!)
        )

        let objectIdentifier = ObjectIdentifier(playerLayer)

        bindings[objectIdentifier] = monitoredPlayer

        if let player = playerLayer.player {
            // TODO: Add a better way to protect against
            // dual registrations for the same player
            keyValueObservation.unregister(
                player
            )

            keyValueObservation.register(
                player,
                for: \.error,
                options: [.new, .old]
            ) { player, change in
                if let error = (change.newValue ?? nil) as? NSError,
                    ((change.oldValue ?? nil) == nil) {
                    binding.dispatchError(
                        "\(error.code)",
                        withMessage: error.localizedFailureReason
                    )
                }
            }
        }
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

    class KeyValueObservation {
        var observations: [ObjectIdentifier: Set<NSKeyValueObservation>] = [:]

        func register<Value>(
            _ player: AVPlayer,
            for keyPath: KeyPath<AVPlayer, Value>,
            options: NSKeyValueObservingOptions,
            changeHandler: @escaping (AVPlayer, NSKeyValueObservedChange<Value>) -> Void
        ) {
            let observation = player.observe(
                keyPath,
                options: options,
                changeHandler: changeHandler
            )

            if var o = observations[ObjectIdentifier(player)] {
                o.insert(observation)
                observations[ObjectIdentifier(player)] = o
            } else {
                observations[ObjectIdentifier(player)] = Set(arrayLiteral: observation)
            }
        }

        func unregister(
            _ player: AVPlayer
        ) {
            if let o = observations[ObjectIdentifier(player)] {
                o.forEach { observation in
                    observation.invalidate()
                }
                observations.removeValue(forKey: ObjectIdentifier(player))
            }
        }
    }
}
