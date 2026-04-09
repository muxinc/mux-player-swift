//
//  ContainerPlayer.swift
//  MuxPlayerSwiftExample
//

import AVKit
import SwiftUI
import MuxPlayerSwift
import MUXSDKStats

struct ContainerPlayer: View {
    var body: some View {
        ContainerPlayerRepresentable(playbackID: playbackID)
            .ignoresSafeArea()
            .background(.black)
            .accessibilityIdentifier("ContainerPlayerView")
    }
}

#Preview {
    ContainerPlayer()
}

// MARK: - Playback Configuration

extension ContainerPlayer {
    private var playbackID: String {
        ProcessInfo.processInfo.playbackID
            ?? "5ICwECLW8900gMTi5eaOkWdYvOkGhtKyBY02uRCT6FOyE"
    }
}

// MARK: - UIKit Bridge

private struct ContainerPlayerRepresentable: UIViewControllerRepresentable {
    let playbackID: String

    func makeUIViewController(context: Context) -> MuxPlayerContainerViewController {
        let controller = MuxPlayerContainerViewController(
            muxMetadata: MUXSDKCustomerData()
        )

        let playerItem = AVPlayerItem(playbackID: playbackID)
        let player = AVPlayer(playerItem: playerItem)
        controller.player = player
        player.play()

        return controller
    }

    func updateUIViewController(
        _ uiViewController: MuxPlayerContainerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: MuxPlayerContainerViewController,
        coordinator: ()
    ) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
