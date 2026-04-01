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
        // TODO: Check DRM expiration
        
        let fileURL = URL(fileURLWithPath: file, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
        if assetFileExists(at: fileURL), !storedAsset.completedWithError {
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
    
    /// Starts a new Download Task. If there was already a task in progress for this playbackID,
    /// tracks that task's progress instead of starting a new one.
    func startDownloadWithPublisher(
        playbackID: String,
        avAsset: AVURLAsset,
        options: DownloadOptions
    ) async -> AnyPublisher<DownloadEvent, Error> {
        // Download Task in-progress. Return events from it instead of starting a new task
        guard downloadTasksByPlaybackID[playbackID] == nil else {
            return subject(for: playbackID).eraseToAnyPublisher()
        }
        
        // configure the new task, and keep track of it
        let subject = subject(for: playbackID)
        let config = AVAssetDownloadConfiguration(asset: avAsset, title: options.readableTitle)
        let task = downloadSession.makeAssetDownloadTask(downloadConfiguration: config)
        task.taskDescription = playbackID
        // do this before we await the index management, so re-entrant calls don't orphan the task
        downloadTasksByPlaybackID[playbackID] = task
        
        // clean up any old files that might exist (due to failed tasks, etc) before starting
        await deleteDownloadedFiles(playbackID: playbackID, removeFromIndex: true)
        // store DownloadOptions, etc in the index before we start
        await index.upsert(StoredAsset.forNewDownload(playbackID: playbackID, options: options))

        // start the task now that we're set up
        task.resume()

        return subject.eraseToAnyPublisher()
    }
    
    func removeDownload(playbackID: String) async {
        logger.log("[Mux-Offline] removeDownload: called for playbackID \(playbackID)")
        
        if let task = downloadTasksByPlaybackID[playbackID] {
            task.cancel()
            downloadTasksByPlaybackID[playbackID] = nil
        }
        await deleteDownloadedFiles(playbackID: playbackID, removeFromIndex: true)
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
                if assetFileExists(at: assetURL), !completedAsset.completedWithError {
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

    private func deleteDownloadedFiles(playbackID: String, removeFromIndex: Bool) async {
        // Attempt to delete the local media file and CKC sidecar if present (if not present, it's fine)
        if let stored = await index.get(playbackID: playbackID) {
            let fm = FileManager.default
            // Delete media file
            if let mediaPath = stored.localPath {
                let mediaURL = URL(fileURLWithPath: mediaPath, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                do {
                    try fm.removeItem(at: mediaURL)
                } catch {
                    // not generally an error condition. file can be gone due to early cancellation or re-entrant calls to this method
                    logger.trace("[Mux-Offline] Failed to delete media file at \(mediaURL.path): \(error)")
                }
            }
            
            // Delete CKC sidecar if any
            if let ckcFilePath = stored.ckcFilePath {
                let ckcFile = URL(fileURLWithPath: ckcFilePath, relativeTo: URL(fileURLWithPath: NSHomeDirectory()))
                do {
                    try fm.removeItem(at: ckcFile)
                } catch {
                    // not generally an error condition. file can be gone due to early cancellation or re-entrant calls to this method
                    logger.trace("[Mux-Offline] Failed to key id file at \(ckcFile.path): \(error)")
                }
            }
        }
        
        if removeFromIndex {
            await index.delete(playbackID: playbackID)
        }
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

    func handleError(for task: URLSessionTask, error: (any Error)) async {
        logger.error("[Mux-Offline] handleError: Error for task with ID \(task.taskIdentifier): \(String(describing: error))")
        
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleError: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
        
        await index.updateIsComplete(playbackID: playbackID, isComplete: true, completeWithError: true)
        await deleteDownloadedFiles(playbackID: playbackID, removeFromIndex: false)
        
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
        await index.updateLocalPathURL(playbackID: playbackID, localPath: relativeLocation)
    }
    
    func handleFinishedDownload(task: AVAssetDownloadTask, location: URL) async {
        logger.info("[Mux-Offline] handleFinishedDownload: For playbackID (taskDescription) for task id=\(task.taskIdentifier)")
        
        guard let playbackID = task.taskDescription else {
            logger.warning("[Mux-Offline] handleFinishedDownload: Missing playbackID (taskDescription) for task id=\(task.taskIdentifier)")
            return
        }
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
