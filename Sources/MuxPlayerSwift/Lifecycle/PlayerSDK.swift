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
    @TaskLocal
    static var shared = PlayerSDK()
    #else
    static let shared = PlayerSDK()
    #endif

    var monitor: Monitor

    var diagnosticsLogger: Logger

    var abrLogger: Logger

    var externalLogger: Logger

    let reverseProxyServer: ReverseProxyServer

    let keyValueObservation = KeyValueObservation()

    let fairPlaySessionManager: FairPlayStreamingSessionManager

    convenience init() {
        let monitor = Monitor()

        #if targetEnvironment(simulator)
        self.init(
            fairPlayStreamingSessionManager: DefaultFairPlayStreamingSessionManager(
                contentKeySession: AVContentKeySession(keySystem: .clearKey),
                errorDispatcher: monitor
            ),
            monitor: monitor
        )
        #else
        let sessionManager = DefaultFairPlayStreamingSessionManager(
            contentKeySession: AVContentKeySession(keySystem: .fairPlayStreaming),
            errorDispatcher: monitor
        )
        sessionManager.sessionDelegate = ContentKeySessionDelegate(
            sessionManager: sessionManager
        )
        self.init(
            fairPlayStreamingSessionManager: sessionManager,
            monitor: monitor
        )
        #endif
    }

    init(
        fairPlayStreamingSessionManager: FairPlayStreamingSessionManager,
        monitor: Monitor
    ) {
        self.fairPlaySessionManager = fairPlayStreamingSessionManager
        self.monitor = monitor

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

        self.externalLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "External"
            )
        )
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
        if case .drm(let drmOptions) = playbackOptions.playbackPolicy,
           let urlAsset = playerItem.asset as? AVURLAsset {
            fairPlaySessionManager.addDRMAsset(
                urlAsset,
                playbackID: playbackID,
                options: drmOptions,
                rootDomain: playbackOptions.rootDomain())
        }
    }

    func registerPlayerLayer(
        playerLayer: AVPlayerLayer,
        monitoringOptions: MonitoringOptions,
        playbackID: String,
        requiresReverseProxying: Bool = false,
        usingDRM: Bool = false
    ) {
        if requiresReverseProxying && !self.reverseProxyServer.hasBeenStarted {
            self.reverseProxyServer.start()
        }

        monitor.setupMonitoring(
            playerLayer: playerLayer,
            playbackID: playbackID,
            options: monitoringOptions,
            usingDRM: usingDRM
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
        playbackID: String,
        requiresReverseProxying: Bool = false,
        usingDRM: Bool = false
    ) {
        if requiresReverseProxying && !self.reverseProxyServer.hasBeenStarted {
            self.reverseProxyServer.start()
        }

        monitor.setupMonitoring(
            playerViewController: playerViewController,
            playbackID: playbackID,
            options: monitoringOptions,
            usingDRM: usingDRM
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
