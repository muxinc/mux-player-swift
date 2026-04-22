//
//  OfflineDownloadManager.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import MuxPlayerSwift

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
            case .playable(let avAsset):
                downloadStates[asset.playbackID] = .downloaded(avAsset)
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
        let playbackOptions = {
            if let playbackToken = asset.playbackToken {
                if let drmToken = asset.drmToken {
                    return PlaybackOptions(playbackToken: playbackToken, drmToken: drmToken)
                } else {
                    return PlaybackOptions(playbackToken: playbackToken)
                }
            } else {
                return PlaybackOptions()
            }
        }()
        
        let stream = await MuxOfflineAccessManager.shared.startDownload(
            playbackID: asset.playbackID,
            playbackOptions: playbackOptions,
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

    /// Returns an `AVURLAsset` suitable for local playback, or `nil`.
    func localAVAsset(for playbackID: String) async -> AVURLAsset? {
        guard let downloaded = await MuxOfflineAccessManager.shared.findDownloadedAsset(
            playbackID: playbackID
        ) else {
            return nil
        }
        return downloaded.avAssetIfPlayable()
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
            if let avAsset = downloadedAsset.avAssetIfPlayable() {
                downloadStates[playbackID] = .downloaded(avAsset)
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
