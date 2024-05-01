//
//  PlayerSDK.swift
//

import AVFoundation
import Foundation

// internal class to manage dependency injection
class PlayerSDK {

    #if DEBUG
    static var shared = PlayerSDK()
    #else
    static let shared = PlayerSDK()
    #endif

    let monitor: Monitor

    let keyValueObservation: KeyValueObservation
    
    let fairPlaySessionManager: FairPlaySessionManager

    init() {
        self.monitor = Monitor()
        self.keyValueObservation = KeyValueObservation()
        self.fairPlaySessionManager = FairPlaySessionManager()
    }

    class KeyValueObservation {

        var observations: [ObjectIdentifier: NSKeyValueObservation] = [:]

        func register<Value>(
            _ player: AVPlayer,
            for keyPath: KeyPath<AVPlayer, Value>,
            options: NSKeyValueObservingOptions,
            changeHandler: @escaping (AVPlayer, NSKeyValueObservedChange<Value>) -> Void
        ) {
            let observation = player.observe(keyPath,
                                             options: options,
                                             changeHandler: changeHandler
            )
            observations[ObjectIdentifier(player)] = observation
        }

        func unregister(
            _ player: AVPlayer
        ) {
            if let observation = observations[ObjectIdentifier(player)] {
                observation.invalidate()
                observations.removeValue(forKey: ObjectIdentifier(player))
            }
        }
    }
}

// MARK extension for observations for DRM
extension PlayerSDK {
    func observePlayerForDRM(_ player: AVPlayer) {
        keyValueObservation.register(
            player,
            for: \AVPlayer.currentItem,
            options: [.old, .new]
        ) { player, change in
            if let oldAsset = change.oldValue??.asset as? AVURLAsset {
                PlayerSDK.shared.fairPlaySessionManager.removeContentKeyRecipient(oldAsset)
            }
        }
    }
    
    func stopObservingPlayerForDrm(_ player: AVPlayer) {
        keyValueObservation.unregister(player)
    }
}
