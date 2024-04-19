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

    init() {
        self.monitor = Monitor()
        self.keyValueObservation = KeyValueObservation()
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
