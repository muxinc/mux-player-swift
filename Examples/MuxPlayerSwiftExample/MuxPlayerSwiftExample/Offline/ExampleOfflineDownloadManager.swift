//
//  ExampleOfflineDownloadManager.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import Combine
import Foundation
import MuxPlayerSwift

enum AssetDownloadState {
    case downloading(progress: Double)
    case downloaded
    case expired
    case mustRedownload
    case error(Error)
}

@MainActor
final class ExampleOfflineDownloadManager: ObservableObject {

    // In your app, this would probably come from your app's backend or CMS
    let exampleAssets: [ExampleAsset] = [
        ExampleAsset(
            playbackID: "zyII9g3ndjv9jOQi7JQh37oAUfLok2kvtdHmlGBPuVc",
            title: "Tears of Steel"
        ),
        ExampleAsset(
            playbackID: "fjE8FXeoV53XONhWPlQp3yl98iv8k02gtj6jvBvKovVo",
            title: "Elephant's Dream"
        ),
        ExampleAsset(
            playbackID: "Q3ikJX28joohwD02j01Ew7yyPYeraJwRjVVXrwZjt9xUo",
            title: "Making of Sintel"
        ),
        ExampleAsset(
            playbackID: "01dsHZ81nZSCx3vVfb1jnzQPC1ZjEQ002w8gfddqxNd9k",
            title: "Sintel"
        ),
        ExampleAsset(
            playbackID: "zrQ02TP4Br02KycnnAJIM8FPnohUZLZprkDC33nWzJavc",
            title: "SF Video Tech Talk"
        ),
        ExampleAsset(
            playbackID: "wXqpSb3E1bI9xdr0100wIZ016j5WwP1HcfE",
            title: "Infrastructure Review"
        )
    ]

    /// Download states keyed by playback ID.
    @Published var downloadStates: [String: AssetDownloadState] = [:]

    /// One Task per playback ID; cancelled when the download finishes,
    /// fails, or is removed by the user.
    private var downloadTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Loading

    func loadExistingDownloads() async {
        let completedAssets = await MuxOfflineAccessManager.shared.allDownloadedAssets()
        for asset in completedAssets {
            switch asset.assetStatus {
            case .playable:
                downloadStates[asset.playbackID] = .downloaded
            case .redownloadWhenOnline:
                downloadStates[asset.playbackID] = .mustRedownload
            case .expired:
                downloadStates[asset.playbackID] = .expired
            }
        }

        let inProgressStreams = await MuxOfflineAccessManager.shared.allInProcessTasks()
        for (playbackID, stream) in inProgressStreams {
            downloadStates[playbackID] = .downloading(progress: 0.0)
            observeDownload(playbackID: playbackID, stream: stream)
        }
    }

    // MARK: - Download Actions
    
    func removeDownload(playbackID: String) async {
        await MuxOfflineAccessManager.shared.removeDownload(playbackID: playbackID)
    }
    
    func startDownload(for asset: ExampleAsset) async {
        let stream = await MuxOfflineAccessManager.shared.startDownload(
            playbackID: asset.playbackID,
            playbackOptions: asset.makePlaybackOptions(),
            downloadOptions: DownloadOptions(readableTitle: asset.title)
        )
        downloadStates[asset.playbackID] = .downloading(progress: 0.0)
        observeDownload(playbackID: asset.playbackID, stream: stream)
    }

    func cancelOrDeleteDownload(for playbackID: String) {
        downloadTasks[playbackID]?.cancel()
        downloadTasks.removeValue(forKey: playbackID)
        Task {
            await MuxOfflineAccessManager.shared.removeDownload(playbackID: playbackID)
            downloadStates.removeValue(forKey: playbackID)
        }
    }

    /// Returns an `AVPlayer` backed by the locally downloaded asset, or `nil`.
    func makePlayer(for playbackID: String) async -> AVPlayer? {
        guard let downloaded = await MuxOfflineAccessManager.shared.findDownloadedAsset(
            playbackID: playbackID
        ), let asset = downloaded.avAssetIfPlayable() else {
            return nil
        }
        return AVPlayer(playerItem: AVPlayerItem(asset: asset))
    }

    // MARK: - Helpers

    /// Sorted list of playback IDs that have a download state.
    var sortedDownloadedPlaybackIDs: [String] {
        downloadStates.keys.sorted()
    }

    func asset(for playbackID: String) -> ExampleAsset? {
        exampleAssets.first { $0.playbackID == playbackID }
    }

    // MARK: - Private

    private func observeDownload(
        playbackID: String,
        stream: AsyncThrowingStream<DownloadEvent, Error>
    ) {
        downloadTasks[playbackID]?.cancel()
        downloadTasks[playbackID] = Task { [weak self] in
            do {
                for try await event in stream {
                    guard !Task.isCancelled else { return }
                    self?.handleDownloadEvent(event, for: playbackID)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self?.handleDownloadError(error, for: playbackID)
            }
            self?.downloadTasks.removeValue(forKey: playbackID)
        }
    }

    private func handleDownloadEvent(_ event: DownloadEvent, for playbackID: String) {
        switch event {
        case .started:
            downloadStates[playbackID] = .downloading(progress: 0.0)
        case .waitingForConnectivity:
            break
        case .progress(let percent):
            downloadStates[playbackID] = .downloading(progress: percent)
        case .completed(let downloadedAsset):
            if downloadedAsset.avAssetIfPlayable() != nil {
                downloadStates[playbackID] = .downloaded
            } else {
                downloadStates[playbackID] = .mustRedownload
            }
        }
    }

    private func handleDownloadError(_ error: Error, for playbackID: String) {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return
        }
        downloadStates[playbackID] = .error(error)
    }
}
