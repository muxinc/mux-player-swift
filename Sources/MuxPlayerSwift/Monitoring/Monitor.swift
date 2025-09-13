//
//  Monitor.swift
//

import AVFoundation
import AVKit
import Foundation

import MuxCore
import MUXSDKStats

/// Wrapper around MUXSDKStats
class PlayerObservationContext {
    func monitorAVPlayerViewController(
        _ player: AVPlayerViewController,
        withPlayerName name: String,
        customerData: MUXSDKCustomerData,
        automaticErrorTracking: Bool
    ) -> MUXSDKPlayerBinding? {
        MUXSDKStats.monitorAVPlayerViewController(
            player,
            withPlayerName: name,
            customerData: customerData,
            automaticErrorTracking: automaticErrorTracking
        )
    }

    func monitorAVPlayerLayer(
        _ player: AVPlayerLayer,
        withPlayerName name: String,
        customerData: MUXSDKCustomerData,
        automaticErrorTracking: Bool
    ) -> MUXSDKPlayerBinding? {
        MUXSDKStats.monitorAVPlayerLayer(
            player,
            withPlayerName: name,
            customerData: customerData,
            automaticErrorTracking: automaticErrorTracking
        )
    }

    func destroyPlayer(
        _ name: String
    ) {
        MUXSDKStats.destroyPlayer(name)
    }
}

class Monitor: ErrorDispatcher {

    struct MonitoredPlayer {
        var name: String
        var binding: MUXSDKPlayerBinding
        var playerIdentifier: ObjectIdentifier
    }

    var bindings: [ObjectIdentifier: MonitoredPlayer] = [:]

    var playbackIDsToPlayerObjectIdentifier: [String: ObjectIdentifier] = [:]

    var playbackIDsToFairPlaySessionErrors: [String: FairPlaySessionError] = [:]

    /// Either AVPlayerViewController, AVPlayerLayer, or AVPlayer
    /// may be used to register bindings with Data.
    /// KVO notices for player updates only have a pointer
    /// to the AVPlayer instance.
    ///
    /// Routing error updates to the right player binding
    /// requires a series of lookups. This is tedious for
    /// AVPlayerViewController, AVPlayerLayer and gets easier
    /// if there's a mapping kept between either of them as
    /// we go along.
    var playerObjectIdentifiersToBindingReferenceObjectIdentifier: [ObjectIdentifier: ObjectIdentifier] = [:]

    let keyValueObservation = KeyValueObservation()

    let playerObservationContext: PlayerObservationContext

    init(
        playerObservationContext: PlayerObservationContext = PlayerObservationContext()
    ) {
        self.playerObservationContext = playerObservationContext
    }

    func setupMonitoring(
        playerViewController: AVPlayerViewController,
        playbackID: String,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        guard let player = playerViewController.player else {
            // TODO: Log
            return
        }

        let customerData: MUXSDKCustomerData

        if let externallySpecifiedCustomerData = options.customerData {

            let modifiedCustomerData = MUXSDKCustomerData()

            if let customerVideoData = externallySpecifiedCustomerData.customerVideoData {
                let copiedCustomerVideoDataCopy = MUXSDKCustomerVideoData()
                copiedCustomerVideoDataCopy.setQuery(customerVideoData.toQuery())
                modifiedCustomerData.customerVideoData = copiedCustomerVideoDataCopy
            }

            if let customerViewData = externallySpecifiedCustomerData.customerViewData {
                let copiedCustomerViewData = MUXSDKCustomerViewData()
                copiedCustomerViewData.setQuery(customerViewData.toQuery())
                modifiedCustomerData.customerViewData = copiedCustomerViewData
            }

            if let customerViewerData = externallySpecifiedCustomerData.customerViewerData {
                let copiedCustomerViewerData = MUXSDKCustomerViewerData()
                copiedCustomerViewerData.viewerApplicationName = customerViewerData.viewerApplicationName
                copiedCustomerViewerData.viewerDeviceCategory = customerViewerData.viewerDeviceCategory
                copiedCustomerViewerData.viewerDeviceManufacturer = customerViewerData.viewerDeviceManufacturer
                copiedCustomerViewerData.viewerDeviceModel = customerViewerData.viewerDeviceModel
                copiedCustomerViewerData.viewerOsFamily = customerViewerData.viewerOsFamily
                copiedCustomerViewerData.viewerOsVersion = customerViewerData.viewerOsVersion
                modifiedCustomerData.customerViewerData = customerViewerData
            }

            if let customData = externallySpecifiedCustomerData.customData {
                let copiedCustomData = MUXSDKCustomData()
                copiedCustomData.setQuery(
                    customData.toQuery()
                )
                modifiedCustomerData.customData = copiedCustomData
            }

            if let customerPlayerData = externallySpecifiedCustomerData.customerPlayerData {
                let copiedCustomerPlayerData = MUXSDKCustomerPlayerData()
                copiedCustomerPlayerData.setQuery(
                    customerPlayerData.toQuery()
                )
                copiedCustomerPlayerData.playerSoftwareVersion = SemanticVersion.versionString
                copiedCustomerPlayerData.playerSoftwareName = "MuxPlayerSwiftAVPlayerViewController"
                modifiedCustomerData.customerPlayerData = copiedCustomerPlayerData
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

        // If using DRM, MuxPlayerSwift tracks errors in order to enrich appcert/CKC request errors
        let shouldTrackErrorsAutomatically = !usingDRM && options.automaticErrorTracking

        let binding = playerObservationContext.monitorAVPlayerViewController(
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
            playerIdentifier: ObjectIdentifier(
                player
            )
        )

        let objectIdentifier = ObjectIdentifier(playerViewController)

        bindings[objectIdentifier] = monitoredPlayer
        playerObjectIdentifiersToBindingReferenceObjectIdentifier[
            ObjectIdentifier(player)
        ] = objectIdentifier

        if let player = playerViewController.player {
            // TODO: Add a better way to protect against
            // dual registrations for the same player
            keyValueObservation.unregister(
                player
            )

            if usingDRM && options.automaticErrorTracking {
                keyValueObservation.register(
                    player,
                    for: \.error,
                    options: [.new, .old]
                ) { [weak binding, weak self] player, change in

                    guard let binding else {
                        return
                    }

                    guard let self else {
                        return
                    }

                    self.handleUpdatedPlayerError(
                        updatedPlayerError: change.newValue ?? nil,
                        previousPlayerError: change.oldValue ?? nil,
                        for: player,
                        using: binding
                    )
                }
            }

            keyValueObservation.register(
                player,
                for: \.currentItem,
                options: [.initial, .new, .old]
            ) { [weak self] player, change in
                guard let self else {
                    return
                }

                self.handleUpdatedCurrentPlayerItem(
                    previousPlayerItem: change.oldValue ?? nil,
                    updatedPlayerItem: change.newValue ?? nil,
                    for: player
                )
            }
        }
    }

    func setupMonitoring(
        playerLayer: AVPlayerLayer,
        playbackID: String,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        guard let player = playerLayer.player else {
            // TODO: Log
            return
        }

        let customerData: MUXSDKCustomerData

        if let externallySpecifiedCustomerData = options.customerData {

            let modifiedCustomerData = MUXSDKCustomerData()

            if let customerVideoData = externallySpecifiedCustomerData.customerVideoData {
                let copiedCustomerVideoData = MUXSDKCustomerVideoData()
                copiedCustomerVideoData.setQuery(customerVideoData.toQuery())
                modifiedCustomerData.customerVideoData = copiedCustomerVideoData
            }

            if let customerViewData = externallySpecifiedCustomerData.customerViewData {
                let copiedCustomerViewData = MUXSDKCustomerViewData()
                copiedCustomerViewData.setQuery(customerViewData.toQuery())
                modifiedCustomerData.customerViewData = copiedCustomerViewData
            }

            if let customerViewerData = externallySpecifiedCustomerData.customerViewerData {
                let copiedCustomerViewerData = MUXSDKCustomerViewerData()
                copiedCustomerViewerData.viewerApplicationName = customerViewerData.viewerApplicationName
                copiedCustomerViewerData.viewerDeviceCategory = customerViewerData.viewerDeviceCategory
                copiedCustomerViewerData.viewerDeviceManufacturer = customerViewerData.viewerDeviceManufacturer
                copiedCustomerViewerData.viewerDeviceModel = customerViewerData.viewerDeviceModel
                copiedCustomerViewerData.viewerOsFamily = customerViewerData.viewerOsFamily
                copiedCustomerViewerData.viewerOsVersion = customerViewerData.viewerOsVersion
                modifiedCustomerData.customerViewerData = customerViewerData
            }

            if let customData = externallySpecifiedCustomerData.customData {
                let copiedCustomData = MUXSDKCustomData()
                copiedCustomData.setQuery(
                    customData.toQuery()
                )
                modifiedCustomerData.customData = copiedCustomData
            }

            if let customerPlayerData = externallySpecifiedCustomerData.customerPlayerData {
                let customerPlayerDataCopy = MUXSDKCustomerPlayerData()
                customerPlayerDataCopy.setQuery(
                    customerPlayerData.toQuery()
                )
                customerPlayerDataCopy.playerSoftwareVersion = SemanticVersion.versionString
                customerPlayerDataCopy.playerSoftwareName = "MuxPlayerSwiftAVPlayerLayer"
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

        let shouldTrackErrorsAutomatically = !usingDRM && options.automaticErrorTracking

        let binding = playerObservationContext.monitorAVPlayerLayer(
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
            playerIdentifier: ObjectIdentifier(
                player
            )
        )

        let objectIdentifier = ObjectIdentifier(playerLayer)

        bindings[objectIdentifier] = monitoredPlayer
        playerObjectIdentifiersToBindingReferenceObjectIdentifier[
            ObjectIdentifier(player)
        ] = objectIdentifier

        if let player = playerLayer.player {
            // TODO: Add a better way to protect against
            // dual registrations for the same player
            keyValueObservation.unregister(
                player
            )

            if usingDRM && options.automaticErrorTracking {
                keyValueObservation.register(
                    player,
                    for: \.error,
                    options: [.new, .old]
                ) { [weak binding, weak self] player, change in

                    guard let binding else {
                        return
                    }

                    guard let self else {
                        return
                    }

                    self.handleUpdatedPlayerError(
                        updatedPlayerError: change.newValue ?? nil,
                        previousPlayerError: change.oldValue ?? nil,
                        for: player,
                        using: binding
                    )
                }
            }

            keyValueObservation.register(
                player,
                for: \.currentItem,
                options: [.initial, .new, .old]
            ) { [weak self] player, change in
                guard let self else {
                    return
                }

                self.handleUpdatedCurrentPlayerItem(
                    previousPlayerItem: change.oldValue ?? nil,
                    updatedPlayerItem: change.newValue ?? nil,
                    for: player
                )
            }
        }
    }

    func tearDownMonitoring(playerViewController: AVPlayerViewController) {

        let objectIdentifier = ObjectIdentifier(playerViewController)

        guard let playerName = bindings[objectIdentifier]?.name else {
            return
        }

        if let player = playerViewController.player {
            keyValueObservation.unregister(
                player
            )
        } else if let playerObjectIdentifier = bindings[objectIdentifier]?.playerIdentifier {
            keyValueObservation.unregister(
                playerObjectIdentifier
            )
        }

        playerObservationContext.destroyPlayer(playerName)

        bindings.removeValue(forKey: objectIdentifier)
    }

    func tearDownMonitoring(playerLayer: AVPlayerLayer) {

        let objectIdentifier = ObjectIdentifier(playerLayer)

        guard let playerName = bindings[objectIdentifier]?.name else {
            return
        }

        if let player = playerLayer.player {
            keyValueObservation.unregister(
                player
            )
        } else if let playerObjectIdentifier = bindings[objectIdentifier]?.playerIdentifier {
            keyValueObservation.unregister(
                playerObjectIdentifier
            )
        }

        playerObservationContext.destroyPlayer(playerName)

        bindings.removeValue(forKey: objectIdentifier)
    }

    // MARK: - Player Item Tracking

    func handleUpdatedCurrentPlayerItem(
        previousPlayerItem:  AVPlayerItem?,
        updatedPlayerItem: AVPlayerItem?,
        for player: AVPlayer
    ) {
        if let updatedPlaybackID = updatedPlayerItem?.playbackID {
            playbackIDsToPlayerObjectIdentifier[updatedPlaybackID] = ObjectIdentifier(player)
        }

        if let previousPlaybackID = previousPlayerItem?.playbackID {
            playbackIDsToPlayerObjectIdentifier[previousPlaybackID] = ObjectIdentifier(player)
        }
    }

    // MARK: - Error Dispatch

    func dispatchApplicationCertificateRequestError(
        error: FairPlaySessionError,
        playbackID: String
    ) {
        playbackIDsToFairPlaySessionErrors[playbackID] = error
    }

    func dispatchLicenseRequestError(
        error: FairPlaySessionError,
        playbackID: String
    ) {
        playbackIDsToFairPlaySessionErrors[playbackID] = error
    }

    func handleUpdatedPlayerError(
        updatedPlayerError: Error?,
        previousPlayerError: Error?,
        for player: AVPlayer,
        using binding: MUXSDKPlayerBinding
    ) {
        if let updatedPlayerError = updatedPlayerError as? NSError,
        previousPlayerError == nil {
            if let currentPlayerItem = player.currentItem,
            let playbackID = currentPlayerItem.playbackID,
            let fairPlaySessionError = self.playbackIDsToFairPlaySessionErrors[
                playbackID
            ] {
                let enrichedErrorMessage = self.enrichErrorMessageIfNecessary(
                    playerError: updatedPlayerError,
                    fairPlaySessionError: fairPlaySessionError
                )

                binding.dispatchError(
                    "\(updatedPlayerError.code)",
                    withMessage: enrichedErrorMessage ?? "No additional information."
                )
            } else {
                binding.dispatchError(
                    "\(updatedPlayerError.code)",
                    withMessage: updatedPlayerError.localizedFailureReason ?? "No additional information."
                )
            }

        }
    }

    func enrichErrorMessageIfNecessary(
        playerError: NSError,
        fairPlaySessionError: FairPlaySessionError
    ) -> String? {

        if case let FairPlaySessionError.httpFailed(
            responseStatusCode
        ) = fairPlaySessionError {
            switch responseStatusCode {
            case 400:
                return "The URL or playback ID was invalid. You may have used an invalid value as a playback ID."
            case 403:
                return "The video's secured drm-token is not authorized for this request. It may be expired or a token for another resource."
            case 404:
                return "This URL or playback ID does not exist. You may have used an Asset ID or an ID from a different resource."
            case 412:
                return "This playback ID may belong to a live stream that is not currently active or an asset that is not ready."
            default:
                break
            }
        }

        return playerError.localizedFailureReason
    }

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

        func unregister(
            _ objectIdentifier: ObjectIdentifier
        ) {
            if let o = observations[objectIdentifier] {
                o.forEach { observation in
                    observation.invalidate()
                }
                observations.removeValue(forKey: objectIdentifier)
            }
        }
    }
}
