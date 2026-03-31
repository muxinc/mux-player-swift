//
//  DownloadManager.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import AVFoundation
import Combine
import os

// MARK: - DownloadManager

// Operations on Downloads, including tasks in-progress, key requests, key storage, and indexing downloaded
// media are isolated here internally. This actor is intended to be called from the external API, `Mux-OfflineAccessManager`,
// which calls through to this actor without introducing reentrancy issues, or requiring any particular concurrency
// management from the caller
actor DownloadManager: NSObject, AVAssetDownloadDelegate {
    private let delegateQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.mux.offline.delegate"
        q.qualityOfService = .utility
        q.maxConcurrentOperationCount = 1 // serialize delegate callbacks
        return q
    }()
    private lazy var downloadDelegate = DownloadTaskDelegate(offlineAccessManager: self)
    private lazy var downloadSession = AVAssetDownloadURLSession(
        configuration: .background(withIdentifier: "Mux-Player-Offline-Access"),
        assetDownloadDelegate: downloadDelegate,
        delegateQueue: delegateQueue
    )
    
    #if DEBUG
    private let logger = Logger(OSLog(subsystem: "com.mux.player", category: "Mux-Offline"))
    #else 
    private let logger = Logger(.disabled)
    #endif

    private let index = DownloadIndex()
    private var downloadTasksByPlaybackID: [String: AVAssetDownloadTask] = [:]
    private var subjectsByPlaybackID: [String: PassthroughSubject<DownloadEvent, Error>] = [:]
    
    func findDownloadedAsset(playbackID: String) async -> DownloadedAsset? {
        guard let storedAsset = await index.get(playbackID: playbackID) else {
            logger.warning("[Mux-Offline] findDownloadedAsset: No stored asset in index for playbackID \(playbackID)")
            return nil
        }
        guard storedAsset.isComplete else {
            logger.warning("[Mux-Offline] findDownloadedAsset: Asset not complete for playbackID \(playbackID)")
            return nil
        }
        guard let file = storedAsset.localPath else {
            logger.warning("[Mux-Offline] findDownloadedAsset: No local path saved for completed asset")
            return nil
        }
        // TODO: Check DRM expiration
        
        let fileURL = URL(fileURLWithPath: file, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
        if assetFileExists(at: fileURL) {
            return DownloadedAsset(
                playbackID: playbackID,
                assetStatus: .playable(asset: AVURLAsset(url: fileURL)),
                downloadOptions: DownloadOptions(from: storedAsset)
            )
        } else {
            return DownloadedAsset(
                playbackID: playbackID,
                assetStatus: .redownloadWhenOnline,
                downloadOptions: DownloadOptions(from: storedAsset)
            )
        }
    }
    
    func startDownloadWithPublisher(
        playbackID: String,
        avAsset: AVURLAsset,
        options: DownloadOptions
    ) async -> AnyPublisher<DownloadEvent, Error> {
        let storedAsset = await index.get(playbackID: playbackID)
        if let storedAsset, storedAsset.isComplete {
            // If we already have a completed download, just return that
            let assetStatus: AssetStatus
            if let file = storedAsset.localPath {
                let fileURL = URL(fileURLWithPath: file, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                if assetFileExists(at: fileURL) {
                    assetStatus = .playable(asset: AVURLAsset(url: fileURL))
                } else {
                    assetStatus = .redownloadWhenOnline
                }
            } else {
                print("[Mux-Offline] startDownloadWithPublisher: No local path saved for completed asset")
                assetStatus = .redownloadWhenOnline
            }

            let downloadedAsset = DownloadedAsset(
                playbackID: playbackID,
                assetStatus: assetStatus,
                downloadOptions: DownloadOptions(from: storedAsset)
            )
            return Just(.completed(downloadedAsset))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            let subject = subject(for: playbackID)
            if downloadTasksByPlaybackID[playbackID] == nil {
                subject.send(.started)
                
                // Do before starting. Better to have index entry without files than files without index entries
                await index.upsert(StoredAsset.forNewDownload(playbackID: playbackID, options: options))
                
                let config = AVAssetDownloadConfiguration(asset: avAsset, title: options.readableTitle)
                let task = downloadSession.makeAssetDownloadTask(downloadConfiguration: config)
                task.taskDescription = playbackID
                task.resume()
                downloadTasksByPlaybackID[playbackID] = task
            }
            
            return subject.eraseToAnyPublisher()
        }
    }
    
    func removeDownload(playbackID: String) async {
        logger.log("[Mux-Offline] removeDownload: called for playbackID \(playbackID)")
        
        if let task = downloadTasksByPlaybackID[playbackID] {
            task.cancel()
            downloadTasksByPlaybackID[playbackID] = nil
        }
        await deleteDownloadedFiles(playbackID: playbackID)
    }
    
    func allCompletedAssets() async -> [DownloadedAsset] {
        await index.all()
            .filter { $0.isComplete }
            .compactMap { completedAsset -> DownloadedAsset? in
                guard let assetPath = completedAsset.localPath else {
                    logger.warning("[Mux-Offline] allCompletedAssets: No local path saved for completed asset")
                    return nil
                }
                let assetURL = URL(fileURLWithPath: assetPath, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                
                // TODO: Check DRM expiration too
                if assetFileExists(at: assetURL) {
                    return DownloadedAsset(
                        playbackID: completedAsset.playbackID,
                        assetStatus: .playable(asset: AVURLAsset(url: assetURL)),
                        downloadOptions: DownloadOptions(from: completedAsset)
                    )
                } else {
                    return DownloadedAsset(
                        playbackID: completedAsset.playbackID,
                        assetStatus: .redownloadWhenOnline,
                        downloadOptions: DownloadOptions(from: completedAsset)
                    )
                }
            }
    }

    func reattachPendingDownloadPublishers() async -> [String: AnyPublisher<DownloadEvent, Error>] {
        let tasks = await tasksFromSession()
        var publishers: [String: AnyPublisher<DownloadEvent, Error>] = [:]
        for task in tasks {
            guard let assetTask = task as? AVAssetDownloadTask else {
                logger.warning("[Mux-Offline] reattachPendingDownloadPublishers: Non-AVAssetDownloadTask encountered: id=\(task.taskIdentifier)")
                continue
            }
            guard let playbackID = assetTask.taskDescription, !playbackID.isEmpty else {
                logger.warning("[Mux-Offline] reattachPendingDownloadPublishers: Missing playbackID (taskDescription) for task id=\(assetTask.taskIdentifier)")
                continue
            }

            downloadTasksByPlaybackID[playbackID] = assetTask
            let subject = subject(for: playbackID)
            publishers[playbackID] = subject.eraseToAnyPublisher()

            assetTask.resume()
        }
        return publishers
    }
    
    func publisherForDownload(playbackID: String) async -> AnyPublisher<DownloadEvent, Error>? {
        guard let subject = subjectsByPlaybackID[playbackID] else {
            return nil
        }
        return subject.eraseToAnyPublisher()
    }
    
    private func assetFileExists(at movPkgURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: movPkgURL.path)
    }
    
    private func tasksFromSession() async -> [URLSessionTask] {
        return await downloadSession.allTasks
    }

    private func deleteDownloadedFiles(playbackID: String) async {
        // Attempt to delete the local media file and CKC sidecar if present (if not present, it's fine)
        if let stored = await index.get(playbackID: playbackID) {
            let fm = FileManager.default
            // Delete media file
            if let mediaPath = stored.localPath {
                let mediaURL = URL(fileURLWithPath: mediaPath, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                try? fm.removeItem(at: mediaURL)
            }
            
            // Delete CKC sidecar if any
            if let ckcFilePath = stored.ckcFilePath {
                let ckcFile = URL(fileURLWithPath: ckcFilePath, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                try? fm.removeItem(at: ckcFile)
            }
        }
        
        // Remove from index regardless
        await index.delete(playbackID: playbackID)
    }
    
    private func subject(for playbackID: String) -> PassthroughSubject<DownloadEvent, Error> {
        if let s = subjectsByPlaybackID[playbackID] { return s }
        let s = PassthroughSubject<DownloadEvent, Error>()
        subjectsByPlaybackID[playbackID] = s
        return s
    }

    private func send(_ event: DownloadEvent, for playbackID: String) {
        subjectsByPlaybackID[playbackID]?.send(event)
    }
    
    private func sendError(_ error: Error, for playbackID: String) {
        subjectsByPlaybackID[playbackID]?.send(completion: .failure(error))
        subjectsByPlaybackID[playbackID] = nil
    }
    
    private func finishEvents(for playbackID: String) {
        if let subject = subjectsByPlaybackID[playbackID] {
            subject.send(completion: .finished)
        }
        subjectsByPlaybackID[playbackID] = nil
    }

    private func detachEvents(for playbackID: String) {
        subjectsByPlaybackID[playbackID] = nil
    }

    // MARK: - Delegate forwarding targets (actor-isolated)

    func handleWaitingForConnectivity(for task: URLSessionTask) {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleWaitingForConnectivity: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        send(.waitingForConnectivity, for: playbackID)
    }

    func handleProgress(task: AVAssetDownloadTask, loadedTimeRanges: [CMTimeRange], expectedTimeRange: CMTimeRange) {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleProgress: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        let loadedSeconds = loadedTimeRanges.reduce(0.0) { $0 + $1.duration.seconds }
        let expectedSeconds = max(expectedTimeRange.duration.seconds, 0.0001)
        let fraction = min(max(loadedSeconds / expectedSeconds, 0.0), 1.0)
        if fraction.isNaN || fraction.isInfinite {
            send(.progress(percent: 0), for: playbackID)
        } else {
            send(.progress(percent: fraction * 100), for: playbackID)
        }
    }

    func handleError(for task: URLSessionTask, error: (any Error)?) {
        logger.error("[Mux-Offline] handleError: Error for task with ID \(task.taskIdentifier): \(String(describing: error))")
        
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleError: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        if let error {
            sendError(error, for: playbackID)
        } else {
            finishEvents(for: playbackID)
        }
        downloadTasksByPlaybackID[playbackID] = nil
        Task { await deleteDownloadedFiles(playbackID: playbackID) }
    }
    
    func handleDownloadLocation(task: AVAssetDownloadTask, relativeLocation: String) async {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleDownloadLocation: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        await index.updateLocalPathURL(playbackID: playbackID, localPath: relativeLocation)
    }
    
    func handleFinishedDownload(task: AVAssetDownloadTask, location: URL) async {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleFinishedDownload: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        let asset = AVURLAsset(url: location)
        let storedAsset = await index.updateIsComplete(playbackID: playbackID, isComplete: true)
        guard let storedAsset else {
            logger.warning("[Mux-Offline] handleFinishedDownload: Index entry missing for playbackID \(playbackID) (may be removed due to reentrancy)")
            return
        }
        let downloadedAsset = DownloadedAsset(
            playbackID: playbackID,
            assetStatus: .playable(asset: asset),
            downloadOptions: DownloadOptions(from: storedAsset)
        )
        
        // Notify listeners
        send(.completed(downloadedAsset), for: playbackID)
        finishEvents(for: playbackID)
        downloadTasksByPlaybackID[playbackID] = nil
    }
}

// MARK: - Internal DTOs

// internal DTO for our index of downloaded assets
struct StoredAsset: Codable {
    let isComplete: Bool
    
    let playbackID: String
    let localPath: String?
    let readableTitle: String
    let posterDataBase64: String?
    let subtitleLanguages: [String]?
    let secondaryAudioLanguages: [String]?
    
    let ckcFilePath: String?
    /// For DRM keys: Either storage or play expiration depending on state
    let keyExpiration: Date?
    /// For secure playback: playback token expiration
    let redownloadExpiration: Date?
}

extension StoredAsset {
    static func forNewDownload(playbackID: String, options: DownloadOptions) -> StoredAsset {
       return StoredAsset(
        isComplete: false,
        playbackID: playbackID,
        localPath: nil,
        readableTitle: options.readableTitle,
        posterDataBase64: options.posterData?.base64EncodedString(),
        subtitleLanguages: options.subtitleLanguages,
        secondaryAudioLanguages: options.secondaryAudioLanguages,
        ckcFilePath: nil,
        keyExpiration: nil,
        redownloadExpiration: nil
       )
    }
    
    func debugString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "StoredAsset(playbackID: \(playbackID), encoding failed)"
        }
        
        return jsonString
    }
}

extension DownloadOptions {
    init(from storedAsset: StoredAsset) {
        self.readableTitle = storedAsset.readableTitle
        
        // Decode base64 string to Data
        if let posterData = storedAsset.posterDataBase64, !posterData.isEmpty {
            self.posterData = Data(base64Encoded: posterData)
        } else {
            self.posterData = nil
        }
        
        self.subtitleLanguages = storedAsset.subtitleLanguages
        self.secondaryAudioLanguages = storedAsset.secondaryAudioLanguages
    }
}


// MARK: - DownloadIndex

// Stores a persistent index of downloaded media, along with sidecar data, DRM keys, etc
actor DownloadIndex {
    
    #if DEBUG
    private let logger = Logger(OSLog(subsystem: "com.mux.player", category: "Mux-Offline"))
    #else
    private let logger = Logger(.disabled)
    #endif
    
    static let plistVersion = 1
    
    // Versioned snapshot persisted as a binary property list under Application Support
    private struct IndexSnapshot: Codable {
        let version: Int
        let assets: [String: StoredAsset]
    }

    private var assets: [String: StoredAsset] = [:]

    init() {
        do {
            if let snapshot = try loadSnapshot() {
                assets = snapshot.assets
            }
        } catch {
            logger.error("[Mux-Offline] DownloadIndex init load error: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

    func upsert(_ asset: StoredAsset) {
        assets[asset.playbackID] = asset
        persist()
    }

    func delete(playbackID: String) {
        assets.removeValue(forKey: playbackID)
        persist()
    }

    func get(playbackID: String) -> StoredAsset? {
        assets[playbackID]
    }

    func all() -> [StoredAsset] {
        Array(assets.values)
    }

    // MARK: - Partial Updates

    func updateIsComplete(playbackID: String, isComplete: Bool) -> StoredAsset? {
        // not an error case. Deletion can occur re-entrantly before the delegate callback that calls this
        guard let existing = assets[playbackID] else {
            logger.warning("[Mux-Offline] DownloadIndex.updateIsComplete: No existing asset for playbackID \(playbackID)")
            return nil
        }
        let updated = StoredAsset(
            isComplete: isComplete,
            playbackID: existing.playbackID,
            localPath: existing.localPath,
            readableTitle: existing.readableTitle,
            posterDataBase64: existing.posterDataBase64,
            subtitleLanguages: existing.subtitleLanguages,
            secondaryAudioLanguages: existing.secondaryAudioLanguages,
            ckcFilePath: existing.ckcFilePath,
            keyExpiration: existing.keyExpiration,
            redownloadExpiration: existing.redownloadExpiration
        )
        assets[playbackID] = updated
        persist()
        
        return updated
    }

    func updateCKCFileURL(playbackID: String, ckcFilePath: String) -> StoredAsset? {
        // not an error case. Deletion can occur re-entrantly before the delegate callback that calls this
        guard let existing = assets[playbackID] else {
            logger.warning("[Mux-Offline] DownloadIndex.updateCKCFileURL: No existing asset for playbackID \(playbackID)")
            return nil
        }
        let updated = StoredAsset(
            isComplete: existing.isComplete,
            playbackID: existing.playbackID,
            localPath: existing.localPath,
            readableTitle: existing.readableTitle,
            posterDataBase64: existing.posterDataBase64,
            subtitleLanguages: existing.subtitleLanguages,
            secondaryAudioLanguages: existing.secondaryAudioLanguages,
            ckcFilePath: ckcFilePath,
            keyExpiration: existing.keyExpiration,
            redownloadExpiration: existing.redownloadExpiration
        )
        assets[playbackID] = updated
        persist()
        
        return updated
    }

    func updateLocalPathURL(playbackID: String, localPath: String) -> StoredAsset? {
        // not an error case. Deletion can occur re-entrantly before the delegate callback that calls this
        guard let existing = assets[playbackID] else {
            logger.warning("[Mux-Offline] DownloadIndex.updateLocalPathURL: No existing asset for playbackID \(playbackID)")
            return nil
        }
        let updated = StoredAsset(
            isComplete: existing.isComplete,
            playbackID: existing.playbackID,
            localPath: localPath,
            readableTitle: existing.readableTitle,
            posterDataBase64: existing.posterDataBase64,
            subtitleLanguages: existing.subtitleLanguages,
            secondaryAudioLanguages: existing.secondaryAudioLanguages,
            ckcFilePath: existing.ckcFilePath,
            keyExpiration: existing.keyExpiration,
            redownloadExpiration: existing.redownloadExpiration
        )
        assets[playbackID] = updated
        persist()
        return updated
    }

    // MARK: - Persistence

    private func persist() {
        do {
            try saveSnapshot(IndexSnapshot(version: Self.plistVersion, assets: assets))
        } catch {
            logger.error("[Mux-Offline] Failed to save index snapshot: \(error.localizedDescription)")
        }
    }

    private func indexDirectoryURL() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = base.appendingPathComponent("com.mux.offline", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        // Exclude from iCloud backups
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDir = dir
        try? mutableDir.setResourceValues(values)
        return dir
    }

    private func indexFileURL() throws -> URL {
        try indexDirectoryURL().appendingPathComponent("index.plist", isDirectory: false)
    }

    private func saveSnapshot(_ snapshot: IndexSnapshot) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(snapshot)

        let url = try indexFileURL()
        let tmp = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try data.write(to: tmp, options: .atomic)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
    }

    private func loadSnapshot() throws -> IndexSnapshot? {
        let url = try indexFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(IndexSnapshot.self, from: data)
    }
}

// MARK: - Extensions

extension DownloadEvent {
    func debugString() -> String {
        switch self {
        case .started:
            return "started"
        case .waitingForConnectivity:
            return "waitingForConnectivity"
        case .progress(let percent):
            return "progress(\(String(format: "%.1f", percent))%)"
        case .completed(let asset):
            return "completed(\(asset.avAssetIfPlayable()?.url.lastPathComponent ?? "unknown"))"
        }
    }
}

// MARK: - Combine to AsyncStream Bridge

extension AnyPublisher {
    func toAsyncThrowingStream() -> AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )
            
            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
}

// MARK: - DownloadTaskDelegate

fileprivate class DownloadTaskDelegate: NSObject, AVAssetDownloadDelegate {
    #if DEBUG
    private let logger = Logger(OSLog(subsystem: "com.mux.player", category: "Mux-Offline"))
    #else
    private let logger = Logger(.disabled)
    #endif

    let downloadManager: DownloadManager
    
    init(offlineAccessManager: DownloadManager) {
        self.downloadManager = offlineAccessManager
    }

    // MARK: AVAssetDownloadDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        logger.error("[Mux-Offline] didCompleteWithError: taskId=\(task.taskIdentifier) error=\(String(describing: error))")
        if let error {
            Task { [downloadManager] in
                await downloadManager.handleError(for: task, error: error)
            }
        }
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        logger.log("[Mux-Offline] didFinishDownloadingTo: taskId=\(assetDownloadTask.taskIdentifier) location=\(location.path)")
        Task { [downloadManager] in
            await downloadManager.handleFinishedDownload(task: assetDownloadTask, location: location)
        }
    }
    
    // Called when a task becomes a download task (general URLSession delegate)
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        logger.log("[Mux-Offline] Task waiting for connectivity: id=\(task.taskIdentifier)")
        Task { [downloadManager] in
            await downloadManager.handleWaitingForConnectivity(for: task)
        }
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange) {
        let loaded = loadedTimeRanges.map { $0.timeRangeValue }
        let loadedDescription = loaded.map { "[start: \($0.start.seconds), dur: \($0.duration.seconds)]" }.joined(separator: ", ")
        logger.trace("[Mux-Offline] didLoad timeRange start=\(timeRange.start.seconds) dur=\(timeRange.duration.seconds) expectedDur=\(timeRangeExpectedToLoad.duration.seconds) loaded=\(loadedDescription)")
        Task { [downloadManager] in
            await downloadManager.handleProgress(task: assetDownloadTask, loadedTimeRanges: loaded, expectedTimeRange: timeRangeExpectedToLoad)
        }
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    willDownloadTo location: URL) {
        logger.log("[Mux-Offline] willDownloadTo [Relative]: \(location.relativePath)")
        Task { [downloadManager] in
            await downloadManager.handleDownloadLocation(task: assetDownloadTask, relativeLocation: location.relativePath)
        }
    }
}

