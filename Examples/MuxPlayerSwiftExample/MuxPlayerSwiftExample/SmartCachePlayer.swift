//
//  SmartCachePlayer.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import SwiftUI
import MuxPlayerSwift

struct SmartCachePlayer: View {
    @State private var singleRenditionResolutionTier: SingleRenditionResolutionTier = .only720p

    var body: some View {
        SmartCachePlayerRepresentable(
            playbackID: playbackID,
            singleRenditionResolutionTier: singleRenditionResolutionTier,
            monitoringOptions: monitoringOptions
        )
        .id(singleRenditionResolutionTier)
        .ignoresSafeArea()
        .background(.black)
        .accessibilityIdentifier("SmartCachePlayerView")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Resolution") {
                    Button("720p") { singleRenditionResolutionTier = .only720p }
                    Button("1080p") { singleRenditionResolutionTier = .only1080p }
                    Button("1440p") { singleRenditionResolutionTier = .only1440p }
                    Button("2160p") { singleRenditionResolutionTier = .only2160p }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SmartCachePlayer()
    }
}

// MARK: - Playback Configuration

extension SmartCachePlayer {
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
                playerName: "MuxPlayerSwift-SmartCacheExample"
            )
        } else {
            MonitoringOptions(
                playbackID: playbackID
            )
        }
    }
}

// MARK: - UIKit Bridge

private struct SmartCachePlayerRepresentable: UIViewControllerRepresentable {
    let playbackID: String
    let singleRenditionResolutionTier: SingleRenditionResolutionTier
    let monitoringOptions: MonitoringOptions

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(
                enableSmartCache: true,
                singleRenditionResolutionTier: singleRenditionResolutionTier
            ),
            monitoringOptions: monitoringOptions
        )
        controller.player?.play()
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) { }

    static func dismantleUIViewController(
        _ uiViewController: AVPlayerViewController,
        coordinator: ()
    ) {
        uiViewController.player?.pause()
        uiViewController.stopMonitoring()
    }
}
