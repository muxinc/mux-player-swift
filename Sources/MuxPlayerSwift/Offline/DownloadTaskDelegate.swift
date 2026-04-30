//
//  DownloadTaskDelegate.swift
//  MuxPlayerSwift
//
//  Extracted from DownloadManager.swift
//

import Foundation
import AVFoundation
import os

class DownloadTaskDelegate: NSObject, AVAssetDownloadDelegate {
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
        // note - AVAssetDownloadDelegate has a seprarate delegate call for task success, didFinishDownloadingTo, which we use instead of reporting it here
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
