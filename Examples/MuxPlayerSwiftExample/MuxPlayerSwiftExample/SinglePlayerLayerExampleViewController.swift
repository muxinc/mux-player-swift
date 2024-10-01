//
//  SinglePlayerLayerExampleViewController.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import UIKit

import MuxPlayerSwift

/// UIView container for AVPlayerLayer
class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            (layer as? AVPlayerLayer)?.player
        }
        set {
            (layer as? AVPlayerLayer)?.player = newValue
        }
    }
}

/// Bare bones AVPlayerLayer example without controls or
/// other affordances
class SinglePlayerLayerExampleViewController: UIViewController {

    // MARK: Mux Data Monitoring Parameters

    var playerName: String = "MuxPlayerSwift-SinglePlayerLayerExample"

    var environmentKey: String? {
        ProcessInfo.processInfo.environmentKey
    }

    var monitoringOptions: MonitoringOptions {
        if let environmentKey {
            MonitoringOptions(
                environmentKey: environmentKey,
                playerName: playerName
            )
        } else {
            MonitoringOptions(
                playbackID: playbackID
            )
        }
    }

    // MARK: Mux Video Playback Parameters

    var playbackID: String {
        ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    // MARK: AVPlayerLayer Container
    lazy var playerView = PlayerView()

    lazy var playerLayer: AVPlayerLayer = AVPlayerLayer()

    var minimumResolutionTier: MinResolutionTier = .default {
        didSet {
            playerLayer.prepare(
                playbackID: playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: maximumResolutionTier,
                    minimumResolutionTier: minimumResolutionTier,
                    renditionOrder: renditionOrder
                ),
                monitoringOptions: monitoringOptions
            )
        }
    }

    var maximumResolutionTier: MaxResolutionTier = .default {
        didSet {
            playerLayer.prepare(
                playbackID: playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: maximumResolutionTier,
                    minimumResolutionTier: minimumResolutionTier,
                    renditionOrder: renditionOrder
                ),
                monitoringOptions: monitoringOptions
            )
        }
    }

    var renditionOrder: RenditionOrder = .default {
        didSet {
            playerLayer.prepare(
                playbackID: playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: maximumResolutionTier,
                    minimumResolutionTier: minimumResolutionTier,
                    renditionOrder: renditionOrder
                ),
                monitoringOptions: monitoringOptions
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.backgroundColor = .black
        view.accessibilityLabel = "A single player example that uses AVPlayerLayer"
        view.accessibilityIdentifier = "SinglePlayerLayerView"

        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        view.addConstraints([
            view.leadingAnchor.constraint(
                equalTo: playerView.leadingAnchor
            ),
            view.trailingAnchor.constraint(
                equalTo: playerView.trailingAnchor
            ),
            view.topAnchor.constraint(
                equalTo: playerView.topAnchor
            ),
            view.bottomAnchor.constraint(
                equalTo: playerView.bottomAnchor
            ),
        ])

        guard let playerLayer = playerView.layer as? AVPlayerLayer else {
            return
        }

        self.playerLayer = playerLayer

        playerLayer.prepare(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(
                maximumResolutionTier: maximumResolutionTier,
                minimumResolutionTier: minimumResolutionTier,
                renditionOrder: renditionOrder
            ),
            monitoringOptions: monitoringOptions
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        playerView.player?.pause()
        playerLayer.stopMonitoring()
        super.viewWillDisappear(animated)
    }
}
