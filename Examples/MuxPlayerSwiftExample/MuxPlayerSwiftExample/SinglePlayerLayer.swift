//
//  SinglePlayerLayer.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import SwiftUI
import MuxPlayerSwift

struct SinglePlayerLayer: View {
    var body: some View {
        PlayerLayerRepresentable(
            playbackID: playbackID,
            monitoringOptions: monitoringOptions
        )
        .ignoresSafeArea()
        .background(.black)
        .accessibilityIdentifier("SinglePlayerLayerView")
    }
}

#Preview {
    SinglePlayerLayer()
}

// MARK: - Playback Configuration

extension SinglePlayerLayer {
    private var playbackID: String {
        ProcessInfo.processInfo.playbackID
            ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    private var environmentKey: String? {
        ProcessInfo.processInfo.environmentKey
    }

    private var monitoringOptions: MonitoringOptions {
        if let environmentKey {
            MonitoringOptions(
                environmentKey: environmentKey,
                playerName: "MuxPlayerSwift-SinglePlayerLayerExample"
            )
        } else {
            MonitoringOptions(
                playbackID: playbackID
            )
        }
    }
}

// MARK: - UIKit Bridge

private struct PlayerLayerRepresentable: UIViewRepresentable {
    let playbackID: String
    let monitoringOptions: MonitoringOptions

    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView()
        playerView.backgroundColor = .black

        playerView.playerLayer.prepare(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(),
            monitoringOptions: monitoringOptions
        )
        playerView.player?.play()

        return playerView
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.player?.pause()
        uiView.playerLayer.stopMonitoring()
    }
}

/// UIView container for AVPlayerLayer
class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    @objc var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    @objc var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    @objc class var keyPathsForValuesAffectingPlayer: Set<String> {
        ["playerLayer.player"]
    }
}
