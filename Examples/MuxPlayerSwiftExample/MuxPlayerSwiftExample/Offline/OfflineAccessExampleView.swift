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
                        if let state = manager.downloadStates[playbackID] {
                            downloadRow(
                                playbackID: playbackID,
                                state: state,
                                asset: manager.asset(for: playbackID)
                            )
                        }
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
            AssetSelectionView(assets: manager.exampleAssets) { asset in
                Task {
                    await manager.startDownload(for: asset)
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
        case .downloading:
            DownloadAssetRow(title: title, state: state, onAction: cancel)
        }
    }

    // MARK: - Playback

    private func playDownloadedAsset(playbackID: String) {
        Task {
            guard let player = await manager.makePlayer(for: playbackID) else { return }
            playerToPresent = PresentedPlayer(player: player)
        }
    }
}

private struct AssetSelectionView: View {
    let assets: [ExampleAsset]
    let onAssetSelected: (ExampleAsset) -> Void

    var body: some View {
        List {
            Section {
                ForEach(assets) { asset in
                    Button {
                        onAssetSelected(asset)
                    } label: {
                        AssetSelectionRow(asset: asset)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Select Asset")
    }
}

private struct AssetSelectionRow: View {
    let asset: ExampleAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(asset.title)
                .foregroundStyle(.primary)
            Text(asset.playbackID)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DownloadAssetRow: View {
    let title: String
    let state: AssetDownloadState
    var onTap: (() -> Void)? = nil
    var onAction: () -> Void
    var onSecondaryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if case .downloading(let progress) = state {
                    ProgressView(value: progress, total: 100)
                }
            }

            Spacer()

            actionButtons
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .downloading: Image(systemName: "arrow.down.circle").foregroundStyle(.blue)
        case .downloaded: Image(systemName: "play.circle.fill").foregroundStyle(.blue)
        case .expired: Image(systemName: "clock.badge.exclamationmark").foregroundStyle(.orange)
        case .mustRedownload: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        case .error: Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch state {
        case .downloading(let progress): "Downloading... \(Int(progress))%"
        case .downloaded: "Downloaded"
        case .expired: "Expired"
        case .mustRedownload: "Must Redownload"
        case .error(let error): error.localizedDescription
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch state {
        case .downloading:
            Button("Cancel", role: .destructive, action: onAction)
                .buttonStyle(.borderless)
        case .downloaded:
            Button("Delete", role: .destructive, action: onAction)
                .buttonStyle(.borderless)
        case .expired, .mustRedownload, .error:
            if let onSecondaryAction {
                Button("Cancel", role: .destructive, action: onSecondaryAction)
                    .buttonStyle(.borderless)
            }
            Button("Retry", action: onAction)
                .buttonStyle(.borderless)
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
