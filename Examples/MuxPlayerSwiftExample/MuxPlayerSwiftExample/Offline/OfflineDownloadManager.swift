//
//  OfflineDownloadManager.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import Combine
import MuxPlayerSwift

@MainActor
final class OfflineDownloadManager: ObservableObject {

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

    /// One Combine subscription per playback ID; removed when the
    /// download finishes, fails, or is cancelled.
    private var downloadSubscriptions: [String: AnyCancellable] = [:]

    // MARK: - Loading

    func loadExistingDownloads() async {
        let completedAssets = await MuxOfflineAccessManager.shared.allDownloadedAssets()
        for asset in completedAssets {
            switch asset.assetStatus {
            case .playable(let avAsset):
                downloadStates[asset.playbackID] = .downloaded(avAsset)
            case .redownloadWhenOnline, .expired:
                downloadStates[asset.playbackID] = .mustRedownload
            }
        }

        let inProgressPublishers = await MuxOfflineAccessManager.shared.allInProcessTasks()
        for (playbackID, publisher) in inProgressPublishers {
            downloadStates[playbackID] = .downloading(progress: 0.0)
            subscribeToDownload(playbackID: playbackID, publisher: publisher)
        }
    }

    // MARK: - Download Actions

    func startDownload(for asset: ExampleAsset) async {
        let publisher = await MuxOfflineAccessManager.shared.startDownload(
            playbackID: asset.playbackID,
            playbackOptions: .init(),
            downloadOptions: DownloadOptions(readableTitle: asset.title)
        )
        downloadStates[asset.playbackID] = .downloading(progress: 0.0)
        subscribeToDownload(playbackID: asset.playbackID, publisher: publisher)
    }

    func cancelOrDeleteDownload(for playbackID: String) {
        downloadSubscriptions.removeValue(forKey: playbackID)
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

    private func subscribeToDownload(
        playbackID: String,
        publisher: AnyPublisher<DownloadEvent, Error>
    ) {
        downloadSubscriptions[playbackID] = publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.downloadSubscriptions.removeValue(forKey: playbackID)
                    if case .failure(let error) = completion {
                        self?.handleDownloadError(error, for: playbackID)
                    }
                },
                receiveValue: { [weak self] event in
                    self?.handleDownloadEvent(event, for: playbackID)
                }
            )
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
