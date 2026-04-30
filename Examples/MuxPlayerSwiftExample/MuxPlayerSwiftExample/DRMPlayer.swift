//
//  DRMPlayer.swift
//  MuxPlayerSwiftExample
//

import AVKit
import SwiftUI
import MuxPlayerSwift

struct DRMPlayer: View {
    var body: some View {
        DRMPlayerRepresentable(
            playbackID: playbackID,
            playbackToken: playbackToken,
            drmToken: drmToken,
            customDomain: customDomain
        )
        .ignoresSafeArea()
        .background(.black)
        .accessibilityIdentifier("DRMPlayerView")
    }
}

#Preview {
    DRMPlayer()
}

// MARK: - Playback Configuration

extension DRMPlayer {
    private var playbackID: String {
        ProcessInfo.processInfo.playbackID
            ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    private var playbackToken: String {
        ProcessInfo.processInfo.playbackToken ?? ""
    }

    private var drmToken: String {
        ProcessInfo.processInfo.drmToken ?? ""
    }

    private var customDomain: String? {
        ProcessInfo.processInfo.customDomain
    }
}

// MARK: - UIKit Bridge

private struct DRMPlayerRepresentable: UIViewControllerRepresentable {
    let playbackID: String
    let playbackToken: String
    let drmToken: String
    let customDomain: String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(
                playbackToken: playbackToken,
                drmToken: drmToken,
                customDomain: customDomain
            )
        )
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.player?.play()
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: AVPlayerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.player?.pause()
        uiViewController.stopMonitoring()
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(true)
        }
    }
}
