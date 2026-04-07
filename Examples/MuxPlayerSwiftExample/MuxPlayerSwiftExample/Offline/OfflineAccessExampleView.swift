//
//  OfflineAccessExampleView.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import MuxPlayerSwift
import SwiftUI

struct OfflineAccessExampleView: View {
    @StateObject private var manager = OfflineDownloadManager()
    @State private var playerToPresent: AVPlayer?

    var body: some View {
        List {
            if !manager.downloadStates.isEmpty {
                Section("My Downloads") {
                    ForEach(manager.sortedDownloadedPlaybackIDs, id: \.self) { playbackID in
                        let state = manager.downloadStates[playbackID] ?? .notDownloaded
                        let asset = manager.asset(for: playbackID)

                        downloadRow(
                            playbackID: playbackID,
                            state: state,
                            asset: asset
                        )
                    }
                }
            }

            Section {
                NavigationLink {
                    AssetSelectionView(
                        assets: manager.exampleAssets
                    ) { asset in
                        Task {
                            await manager.startDownload(for: asset)
                        }
                    }
                } label: {
                    Label("Download New Asset", systemImage: "plus.circle.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Offline Assets")
        .task {
            await manager.loadExistingDownloads()
        }
        .fullScreenCover(item: $playerToPresent) { player in
            PlayerViewControllerRepresentable(player: player)
                .ignoresSafeArea()
        }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func downloadRow(
        playbackID: String,
        state: AssetDownloadState,
        asset: ExampleAsset?
    ) -> some View {
        switch state {
        case .mustRedownload, .error:
            if let asset {
                DownloadAssetRow(
                    title: asset.title,
                    state: state,
                    onAction: {
                        Task { await manager.startDownload(for: asset) }
                    },
                    onSecondaryAction: {
                        manager.cancelOrDeleteDownload(for: playbackID)
                    }
                )
            } else {
                DownloadAssetRow(
                    title: "Unknown Asset",
                    state: state,
                    onAction: {
                        manager.cancelOrDeleteDownload(for: playbackID)
                    }
                )
            }
        case .downloaded:
            DownloadAssetRow(
                title: asset?.title ?? "Unknown Asset",
                state: state,
                onTap: {
                    playDownloadedAsset(playbackID: playbackID)
                },
                onAction: {
                    manager.cancelOrDeleteDownload(for: playbackID)
                }
            )
        case .downloading, .notDownloaded:
            DownloadAssetRow(
                title: asset?.title ?? "Unknown Asset",
                state: state,
                onAction: {
                    manager.cancelOrDeleteDownload(for: playbackID)
                }
            )
        }
    }

    // MARK: - Playback

    private func playDownloadedAsset(playbackID: String) {
        Task {
            guard let avAsset = await manager.localAVAsset(for: playbackID) else {
                return
            }
            let playerItem = AVPlayerItem(asset: avAsset)
            let player = AVPlayer(playerItem: playerItem)
            playerToPresent = player
        }
    }
}

// MARK: - AVPlayer + Identifiable (for fullScreenCover)

extension AVPlayer: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
