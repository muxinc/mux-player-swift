//
//  PlayerSDK.swift
//

import AVFoundation
import AVKit
import Foundation
import os

// internal class to manage dependency injection
class PlayerSDK {
    #if DEBUG
    static var shared = PlayerSDK()
    #else
    static let shared = PlayerSDK()
    #endif

    let monitor: Monitor

    var diagnosticsLogger: Logger

    var abrLogger: Logger

    let reverseProxyServer: ReverseProxyServer

    let keyValueObservation = KeyValueObservation()

    let fairPlaySessionManager: FairPlayStreamingSessionManager

    convenience init() {
        #if targetEnvironment(simulator)
        self.init(
            fairPlayStreamingSessionManager: DefaultFairPlayStreamingSessionManager(
                contentKeySession: AVContentKeySession(keySystem: .clearKey),
                urlSession: .shared
            )
        )
        #else
        let sessionManager = DefaultFairPlayStreamingSessionManager(
            contentKeySession: AVContentKeySession(keySystem: .fairPlayStreaming),
            urlSession: .shared
        )
        sessionManager.sessionDelegate = ContentKeySessionDelegate(
            sessionManager: sessionManager
        )
        self.init(
            fairPlayStreamingSessionManager: sessionManager
        )
        #endif
    }

    init(
        fairPlayStreamingSessionManager: FairPlayStreamingSessionManager
    ) {
        self.monitor = Monitor()
        self.fairPlaySessionManager = fairPlayStreamingSessionManager

        #if DEBUG
        self.abrLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "ABR"
            )
        )
        self.diagnosticsLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "Diagnostics"
            )
        )
        #else
        self.abrLogger = Logger(
            .disabled
        )
        self.diagnosticsLogger = Logger(
            .disabled
        )
        #endif

        self.reverseProxyServer = ReverseProxyServer()
    }

    func enableLogging() {
        self.abrLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "ABR"
            )
        )
        self.diagnosticsLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "Diagnostics"
            )
        )
        self.fairPlaySessionManager.logger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "CK"
            )
        )
    }

    func disableLogging() {
        self.abrLogger = Logger(
            .disabled
        )
        self.diagnosticsLogger = Logger(
            .disabled
        )
        self.fairPlaySessionManager.logger = Logger(
            .disabled
        )
    }

    func registerPlayerItem(
        _ playerItem: AVPlayerItem,
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        // as? AVURLAsset check should never fail
        if case .drm = playbackOptions.playbackPolicy,
           let urlAsset = playerItem.asset as? AVURLAsset {
            fairPlaySessionManager.registerPlaybackOptions(
                playbackOptions,
                for: playbackID
            )
            // asset must be attached as early as possible to avoid crashes when attaching later
            fairPlaySessionManager.addContentKeyRecipient(
                urlAsset
            )
        }
    }

    func registerPlayerLayer(
        playerLayer: AVPlayerLayer,
        monitoringOptions: MonitoringOptions,
        requiresReverseProxying: Bool = false
    ) {
        if requiresReverseProxying && !self.reverseProxyServer.hasBeenStarted {
            self.reverseProxyServer.start()
        }

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
        if requiresReverseProxying && !self.reverseProxyServer.hasBeenStarted {
            self.reverseProxyServer.start()
        }

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
        ), urlAsset.url.isReverseProxyable else {
            return
        }

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
