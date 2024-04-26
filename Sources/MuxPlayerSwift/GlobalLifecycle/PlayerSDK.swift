//
//  PlayerSDK.swift
//

import AVFoundation
import AVKit
import Foundation
import os

// internal class to manage dependency injection
class PlayerSDK {

    static let shared = PlayerSDK()

    let monitor: Monitor

    let diagnosticsLogger: Logger

    let abrLogger: Logger

    let reverseProxyServer: ReverseProxyServer

    let keyValueObservation = KeyValueObservation()

    init() {
        self.monitor = Monitor()
        self.diagnosticsLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "Diagnostics"
            )
        )

        #if DEBUG
        self.abrLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "ABR"
            )
        )
        #else
        self.abrLogger = Logger(
            .disabled
        )
        #endif

        self.reverseProxyServer = ReverseProxyServer()

        self.reverseProxyServer.start()
    }

    func registerPlayerLayer(
        playerLayer: AVPlayerLayer,
        monitoringOptions: MonitoringOptions,
        requiresReverseProxying: Bool = false
    ) {
        monitor.setupMonitoring(
            playerLayer: playerLayer,
            options: monitoringOptions
        )

        if let player = playerLayer.player, 
        requiresReverseProxying == true {
            keyValueObservation.register(
                player,
                for: \.error,
                options: [.new]
            ) { player, observedChange in
                self.handlePlayerError(player)
            }
        }
    }

    func registerPlayerViewController(
        playerViewController: AVPlayerViewController,
        monitoringOptions: MonitoringOptions,
        requiresReverseProxying: Bool = false
    ) {
        monitor.setupMonitoring(
            playerViewController: playerViewController,
            options: monitoringOptions
        )

        if let player = playerViewController.player,
        requiresReverseProxying == true {
            keyValueObservation.register(
                player,
                for: \.error,
                options: [.new]
            ) { player, observedChange in
                self.handlePlayerError(player)
            }
        }
    }

    func handlePlayerError(
        _ player: AVPlayer
    ) {
        guard let urlAsset = player.currentItem?.asset as? AVURLAsset else {
            return
        }

        guard let components = URLComponents(
            url: urlAsset.url,
            resolvingAgainstBaseURL: false
        ) else {
            return
        }

        if let port = components.port,
           components.scheme == "http",
           port == reverseProxyServer.port {
            guard let originURLQueryComponentValue = components.queryItems?.first(
                where: { $0.name == self.reverseProxyServer.originURLKey }
            )?.value else {
                // TODO: Handle more gracefully
                fatalError("Invalid origin URL")
            }

            guard let originURL = URL(string: originURLQueryComponentValue) else {
                // TODO: Handle more gracefully
                fatalError("Invalid origin URL")
            }

            let playerItem = AVPlayerItem(
                url: originURL
            )

            player.replaceCurrentItem(
                with: playerItem
            )
        }
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
