//
//  DownloadIndex.swift
//  MuxPlayerSwift
//
//  Extracted from DownloadManager.swift
//

import Foundation
import os

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

    func updateIsComplete(playbackID: String, isComplete: Bool, completeWithError: Bool) -> StoredAsset? {
        // not an error case. Deletion can occur re-entrantly before the delegate callback that calls this
        guard let existing = assets[playbackID] else {
            logger.warning("[Mux-Offline] DownloadIndex.updateIsComplete: No existing asset for playbackID \(playbackID)")
            return nil
        }
        let updated = StoredAsset(
            isComplete: isComplete,
            completedWithError: completeWithError,
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
            completedWithError: existing.completedWithError,
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
            completedWithError: existing.completedWithError,
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
        do {
            try mutableDir.setResourceValues(values)
        } catch {
            // not generally an error condition. if the index is restored, callers will see .mustRedownload for all entries. not the end of the world
            logger.warning("[Mux-Offline] failed to exclude \(mutableDir) from backup. continuing anyway")
        }
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
        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } catch {
            try data.write(to: url)
        }
    }

    private func loadSnapshot() throws -> IndexSnapshot? {
        let url = try indexFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(IndexSnapshot.self, from: data)
    }
}
