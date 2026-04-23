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
actor DownloadManager {
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
    
    private var reattachedTasks: Bool = false
    private let index = DownloadIndex()
    private var downloadTasksByPlaybackID: [String: AVAssetDownloadTask] = [:]
    private var subjectsByPlaybackID: [String: CurrentValueSubject<DownloadEvent, Error>] = [:]
    
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

        if storedAsset.isExpired() {
            return DownloadedAsset(
                playbackID: playbackID,
                assetStatus: .expired,
                downloadOptions: DownloadOptions(from: storedAsset)
            )
        }

        let fileURL = URL(fileURLWithPath: file, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
        if assetFileExists(at: fileURL), !storedAsset.completedWithError {
            let urlAsset = AVURLAsset(url: fileURL)
            if storedAsset.ckcFilePath != nil {
                await addDRMInfoTo(urlAsset, playbackID: playbackID)
            }
            
            return DownloadedAsset(
                playbackID: playbackID,
                assetStatus: .playable(asset: urlAsset),
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
    
    /// tracks that task's progress instead of starting a new one.
    func startDownloadWithPublisher(
        playbackID: String,
        avAsset: AVURLAsset,
        downloadOptions: DownloadOptions,
        playbackOptions: PlaybackOptions
    ) async -> AnyPublisher<DownloadEvent, Error> {
        logger.trace("Downloading: \(avAsset.url)")
        
        // If we already have a completed asset, return it. Caller can use it, or if it's not playable, they can explicitly delete
        let alreadyCompletedAsset = await findDownloadedAsset(playbackID: playbackID)
        if let alreadyCompletedAsset {
            return Just(.completed(alreadyCompletedAsset))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Download Task in-progress. Return events from it instead of starting a new task
        guard downloadTasksByPlaybackID[playbackID] == nil else {
            return subject(for: playbackID).eraseToAnyPublisher()
        }
        
        // configure the new task, and keep track of it
        let subject = subject(for: playbackID)
        let config = AVAssetDownloadConfiguration(asset: avAsset, title: downloadOptions.readableTitle)
        let task = downloadSession.makeAssetDownloadTask(downloadConfiguration: config)
        task.taskDescription = playbackID
        // do this before we await the index management, so re-entrant calls don't orphan the task
        downloadTasksByPlaybackID[playbackID] = task
        
        // clean up any old files that might exist (due to failed tasks, etc) before starting
        await index.deleteDownloadedFiles(playbackID: playbackID, removeFromIndex: true)
        // store DownloadOptions, etc in the index before we start
        let drmClaims: DRMTokenClaims? = {
            if case .drm(let drmOptions) = playbackOptions.playbackPolicy {
                return DRMTokenClaims.from(drmToken: drmOptions.drmToken)
            }
            return nil
        }()
        await index.upsert(StoredAsset.forNewDownload(playbackID: playbackID, options: downloadOptions, drmClaims: drmClaims))
        
        // Adds the asset as a ContentKeyRecipient, if it's DRM-protected
        if case .drm(let drmOptions) = playbackOptions.playbackPolicy {
            PlayerSDK.shared.registerOfflineDRMAsset(avAsset, playbackID: playbackID, playbackOptions: playbackOptions)
        }
        
        // start the task now that we're set up
        task.resume()
        
        return subject.eraseToAnyPublisher()
    }
    
    func removeDownload(playbackID: String) async {
        logger.log("[Mux-Offline] removeDownload: called for playbackID \(playbackID)")
        
        if let task = downloadTasksByPlaybackID[playbackID] {
            task.cancel()
            PlayerSDK.shared.fairPlaySessionManager.removeOfflineDownloadSession(playbackID: playbackID)
            
            downloadTasksByPlaybackID[playbackID] = nil
            // will also clear the subject, to avoid saving stale state
            sendError(URLError(.cancelled), for: playbackID)
        }
        await index.deleteDownloadedFiles(playbackID: playbackID, removeFromIndex: true)
    }
    
    /// If an asset is stored in the index (completed or not), and it has a persisted content key, returns it
    func findPeristedContentKey(playbackID: String) async throws -> Data? {
        guard let storedAsset = await index.get(playbackID: playbackID),
              let localFile = storedAsset.ckcFilePath
        else {
            return nil
        }
        
        let ckcFileDir = try DownloadIndex.persistenKeyDirectory()
        let fileURL = URL(fileURLWithPath: localFile, relativeTo: ckcFileDir)
        guard assetFileExists(at: fileURL) else {
            logger.warning("CKC file doesn't exist for \(playbackID) at \(fileURL.absoluteString)")
            return nil
        }
        return FileManager.default.contents(atPath: fileURL.path)
    }
    
    /// Starts a new Download Task. If there was already a task in progress for this playbackID,
    func savePersistedContentKey(playbackID: String, identifier: String, contentKeyData: Data) async throws {
        guard let asset = await index.get(playbackID: playbackID) else {
            logger.warning("[Mux-Offline] tried to save persistent key for non-indexed playbackID: \(playbackID)")
            return
        }
        
        try FileManager.default.createDirectory(
            at: DownloadIndex.persistenKeyDirectory(),
            withIntermediateDirectories: true
        )

        // Clean up old file if it exists
        if let existingFile = asset.ckcFilePath {
            let existingURL = try persistentKeyFile(playbackID: playbackID, identifier: identifier)
            do {
                try FileManager.default.removeItem(at: existingURL)
            } catch {
                logger.trace("Failed to delete existing CKC file (probably didn't exist): \(error)")
            }
        }
        
        let newCkcFileURL = try persistentKeyFile(playbackID: playbackID, identifier: identifier)
        logger.info("Saving CKC to file at: \(newCkcFileURL.relativePath)")
        
        // update index first. Better to have blank entries here than orphaned files on disk
        await index.updateCKCFileURL(playbackID: playbackID, ckcFilePath: newCkcFileURL.relativePath)
        
        try contentKeyData.write(to: newCkcFileURL)
        
        logger.info("Saved CKC to file at: \(newCkcFileURL.absoluteString)")
        
        PlayerSDK.shared.fairPlaySessionManager.removeOfflineDownloadSession(playbackID: playbackID)
    }
    
    func updateExpirationPhase(playbackID: String, phase: ExpirationPhase) async {
        await index.updateExpirationPhase(playbackID: playbackID, phase: phase)
    }

    func allCompletedAssets() async -> [DownloadedAsset] {
        let completedAssets = await index.all()
            .filter { $0.isComplete }
            .compactMap { completedAsset -> DownloadedAsset? in
                guard let assetPath = completedAsset.localPath else {
                    logger.warning("[Mux-Offline] allCompletedAssets: No local path saved for completed asset")
                    return nil
                }
                let assetURL = URL(fileURLWithPath: assetPath, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                let urlAsset = AVURLAsset(url: assetURL)

                if completedAsset.isExpired() {
                    return DownloadedAsset(
                        playbackID: completedAsset.playbackID,
                        assetStatus: .expired,
                        downloadOptions: DownloadOptions(from: completedAsset)
                    )
                }

                if assetFileExists(at: assetURL), !completedAsset.completedWithError {
                    return DownloadedAsset(
                        playbackID: completedAsset.playbackID,
                        assetStatus: .playable(asset: urlAsset),
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
        
        for asset in completedAssets {
            if let urlAsset = asset.avAssetIfPlayable() {
                await addDRMInfoTo(urlAsset, playbackID: asset.playbackID)
            }
        }
        
        return completedAssets
    }
    
    func allInProgressTasks() async -> [String: AnyPublisher<DownloadEvent, Error>] {
        return subjectsByPlaybackID.mapValues { $0.eraseToAnyPublisher() }
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
        
        self.reattachedTasks = true
        return publishers
    }
    
    func publisherForDownload(playbackID: String) async -> AnyPublisher<DownloadEvent, Error>? {
        guard let subject = subjectsByPlaybackID[playbackID] else {
            return nil
        }
        return subject.eraseToAnyPublisher()
    }
    
    private func addDRMInfoTo(_ urlAsset: AVURLAsset, playbackID: String) async {
        let persistedContentKey: Data?
        do {
            persistedContentKey = await try findPeristedContentKey(playbackID: playbackID)
        } catch {
            logger.warning("Couldn't find persisted content key for \(playbackID): \(error)")
            return
        }
        // We are only sending to the main actor so we know this will be safe
        if let persistedContentKey {
            await PlayerSDK.shared.fairPlaySessionManager.addOfflinePlayDRMAsset(
                urlAsset,
                playbackID: playbackID,
                keyData: persistedContentKey
            )
        }
    }
    
    private func persistentKeyFile(playbackID: String, identifier: String) throws -> URL {
        let sanitizedIdentifier = identifier.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        guard let sanitizedIdentifier else {
            throw FairPlaySessionError.unexpected(message: "Failed to santiize key identifier [\(identifier)]")
        }
        
        let sanitizedName = "\(playbackID)-\(sanitizedIdentifier)"
        let fileName = "\(sanitizedName).key"
        let directoryURL = try DownloadIndex.persistenKeyDirectory()
        return URL(fileURLWithPath: fileName, relativeTo: directoryURL)
    }
    
    
    private func assetFileExists(at movPkgURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: movPkgURL.path)
    }
    
    private func tasksFromSession() async -> [URLSessionTask] {
        return await downloadSession.allTasks
    }

    
    private func subject(for playbackID: String) -> CurrentValueSubject<DownloadEvent, Error> {
        if let existingSubject = subjectsByPlaybackID[playbackID] { return existingSubject }
        
        let newSubject = CurrentValueSubject<DownloadEvent, Error>(.started)
        subjectsByPlaybackID[playbackID] = newSubject
        return newSubject
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
    
    private func isCurrentTask(_ task: URLSessionTask, for playbackID: String) -> Bool {
        guard self.reattachedTasks else {
            // before we reattach tasks, downloadTasksByPlaybackID is always empty,
            //  but restored tasks' events must stil be handled
            return true
        }
        guard let currentTask = downloadTasksByPlaybackID[playbackID] else {
            return false
        }
        return currentTask.taskIdentifier == task.taskIdentifier
    }
    
    // MARK: - Delegate forwarding targets (actor-isolated)

    func handleWaitingForConnectivity(for task: URLSessionTask) {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleWaitingForConnectivity: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        guard isCurrentTask(task, for: playbackID) else {
            logger.debug("[Mux-Offline] Ignoring stale error callback for playbackID \(playbackID), task id=\(task.taskIdentifier)")
            return
        }
        send(.waitingForConnectivity, for: playbackID)
    }

    func handleProgress(task: AVAssetDownloadTask, loadedTimeRanges: [CMTimeRange], expectedTimeRange: CMTimeRange) {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleProgress: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        guard isCurrentTask(task, for: playbackID) else {
            logger.debug("[Mux-Offline] Ignoring stale error callback for playbackID \(playbackID), task id=\(task.taskIdentifier)")
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

    func handleError(for task: URLSessionTask, error: (any Error)) async {
        logger.error("[Mux-Offline] handleError: Error for task with ID \(task.taskIdentifier): \(String(describing: error))")
        
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleError: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        guard isCurrentTask(task, for: playbackID) else {
            logger.debug("[Mux-Offline] Ignoring stale error callback for playbackID \(playbackID), task id=\(task.taskIdentifier)")
            return
        }

        await index.updateIsComplete(playbackID: playbackID, isComplete: true, completeWithError: true)
        // Once a task errors, we can't resume where we left off, so just delete any partially-downloaded data
        await index.deleteDownloadedFiles(playbackID: playbackID, removeFromIndex: false)
        PlayerSDK.shared.fairPlaySessionManager.removeOfflineDownloadSession(playbackID: playbackID)
        
        // do these after the awaits, so callers that call startDownload to handle errors actually start one
        sendError(error, for: playbackID)
        downloadTasksByPlaybackID[playbackID] = nil
        detachEvents(for: playbackID)
    }
    
    func handleDownloadLocation(task: AVAssetDownloadTask, relativeLocation: String) async {
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleDownloadLocation: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        guard isCurrentTask(task, for: playbackID) else {
            logger.debug("[Mux-Offline] Ignoring stale error callback for playbackID \(playbackID), task id=\(task.taskIdentifier)")
            return
        }
        await index.updateLocalPathURL(playbackID: playbackID, localPath: relativeLocation)
    }
    
    func handleFinishedDownload(task: AVAssetDownloadTask, location: URL) async {
        logger.info("[Mux-Offline] handleFinishedDownload: For playbackID (taskDescription) for task id=\(task.taskIdentifier)")
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleFinishedDownload: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        guard isCurrentTask(task, for: playbackID) else {
            logger.debug("[Mux-Offline] Ignoring stale error callback for playbackID \(playbackID), task id=\(task.taskIdentifier)")
            return
        }

        // Ensure localPath is set even if willDownloadTo's Task hasn't
        // run yet (actor task scheduling is not FIFO)
        await index.updateLocalPathURL(playbackID: playbackID, localPath: location.relativePath)

        let asset = AVURLAsset(url: location)
        let storedAsset = await index.updateIsComplete(playbackID: playbackID, isComplete: true, completeWithError: false)
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
        detachEvents(for: playbackID)
    }
}
