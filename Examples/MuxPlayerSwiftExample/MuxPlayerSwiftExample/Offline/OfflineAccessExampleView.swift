//
//  OfflineAccessExampleView.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import SwiftUI

struct OfflineAccessExampleView: View {
    @StateObject private var manager = ExampleOfflineDownloadManager()
    @State private var isAssetSelectionPresented = false
    @State private var playerToPresent: PresentedPlayer?

    var body: some View {
        List {
            if !manager.downloadStates.isEmpty {
                Section("My Downloads") {
                    ForEach(manager.sortedDownloadedPlaybackIDs, id: \.self) { playbackID in
                        downloadRow(
                            playbackID: playbackID,
                            state: manager.downloadStates[playbackID] ?? .notDownloaded,
                            asset: manager.asset(for: playbackID)
                        )
                    }
                }
            }

            Section {
                Button {
                    isAssetSelectionPresented = true
                } label: {
                    Label("Download New Asset", systemImage: "plus.circle.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Offline Assets")
        .navigationDestination(isPresented: $isAssetSelectionPresented) {
            AssetSelectionView(assets: manager.exampleAssets) { asset, mediaSelectionPolicy in
                Task {
                    await manager.startDownload(for: asset, mediaSelectionPolicy: mediaSelectionPolicy)
                    isAssetSelectionPresented = false
                }
            }
        }
        .task {
            await manager.loadExistingDownloads()
        }
        .fullScreenCover(item: $playerToPresent) { presented in
            OfflinePlayerView(player: presented.player)
                .ignoresSafeArea()
                .background(.black)
        }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func downloadRow(
        playbackID: String,
        state: AssetDownloadState,
        asset: ExampleAsset?
    ) -> some View {
        let title = asset?.title ?? "Unknown Asset"
        let cancel: () -> Void = { manager.cancelOrDeleteDownload(for: playbackID) }

        switch state {
        case .downloaded:
            DownloadAssetRow(
                title: title,
                state: state,
                onTap: { playDownloadedAsset(playbackID: playbackID) },
                onAction: cancel
            )
        case .expired, .mustRedownload, .error:
            if let asset {
                DownloadAssetRow(
                    title: title,
                    state: state,
                    onAction: {
                        Task {
                            await manager.removeDownload(playbackID: playbackID)
                            await manager.startDownload(for: asset)
                        }
                    },
                    onSecondaryAction: cancel
                )
            } else {
                DownloadAssetRow(title: title, state: state, onAction: cancel)
            }
        case .downloading, .notDownloaded:
            DownloadAssetRow(title: title, state: state, onAction: cancel)
        }
    }

    // MARK: - Playback

    private func playDownloadedAsset(playbackID: String) {
        Task {
            guard let asset = await manager.localAVAsset(for: playbackID) else { return }
            let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            playerToPresent = PresentedPlayer(player: player)
        }
    }
}

// MARK: - Presentation Wrapper

private struct PresentedPlayer: Identifiable {
    let id = UUID()
    let player: AVPlayer
}

// MARK: - UIKit Bridge

private struct OfflinePlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        player.play()
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: AVPlayerViewController,
        coordinator: ()
    ) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
