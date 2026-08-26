//
//  DownloadIndex.swift
//  MuxPlayerSwift
//
//  Extracted from DownloadManager.swift
//

import Foundation
import os

#if os(iOS)

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

    private var assets: [String: StoredAsset]

    init() {
        do {
            if let snapshot = try Self.loadSnapshot() {
                assets = snapshot.assets
            } else {
                assets = [:]
            }
        } catch {
            logger.error("[Mux-Offline] DownloadIndex init load error: \(error.localizedDescription)")
            assets = [:]
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
    
    func deleteDownloadedFiles(playbackID: String, removeFromIndex: Bool) async {
        // Attempt to delete the local media file and CKC sidecar if present (if not present, it's fine)
        if let stored = get(playbackID: playbackID) {
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
                do {
                    let ckcDir = try Self.persistentKeyDirectory()
                    let ckcFile = URL(fileURLWithPath: ckcFilePath, relativeTo: ckcDir)
                    try fm.removeItem(at: ckcFile)
                } catch {
                    // not generally an error condition. file can be gone due to early cancellation or re-entrant calls to this method
                    logger.trace("[Mux-Offline] Failed to key id file at \(ckcFilePath): \(error)")
                }
            }
        }
        
        if removeFromIndex {
            delete(playbackID: playbackID)
        }
    }

    // MARK: - Partial Updates

    /// Applies `changes` to the indexed asset and persists the result. Every
    /// partial update goes through here so new `StoredAsset` fields are carried
    /// over without having to be repeated in each updater.
    @discardableResult
    private func mutate(
        playbackID: String,
        caller: StaticString = #function,
        changes: (inout StoredAsset) -> Void
    ) -> StoredAsset? {
        // not an error case. Deletion can occur re-entrantly before the delegate callback that calls this
        guard var updated = assets[playbackID] else {
            logger.warning("[Mux-Offline] DownloadIndex.\(String(describing: caller)): No existing asset for playbackID \(playbackID)")
            return nil
        }
        changes(&updated)
        assets[playbackID] = updated
        persist()

        return updated
    }

    @discardableResult
    func updateIsComplete(playbackID: String, isComplete: Bool, completeWithError: Bool) -> StoredAsset? {
        mutate(playbackID: playbackID) {
            $0.isComplete = isComplete
            $0.completedWithError = completeWithError
        }
    }

    @discardableResult
    func updateCKCFileURL(playbackID: String, ckcFilePath: String?, keyIdentifier: String?) -> StoredAsset? {
        mutate(playbackID: playbackID) {
            $0.ckcFilePath = ckcFilePath
            $0.keyIdentifier = keyIdentifier
        }
    }

    @discardableResult
    func updateLocalPathURL(playbackID: String, localPath: String) -> StoredAsset? {
        mutate(playbackID: playbackID) {
            $0.localPath = localPath
        }
    }

    @discardableResult
    func updateExpirationPhase(playbackID: String, phase: ExpirationPhase) -> StoredAsset? {
        mutate(playbackID: playbackID) {
            $0.expireLicenseFrom = Date()
            $0.expirationPhase = phase
        }
    }

    /// Restarts the expiration clock from a freshly-issued license's claims. The
    /// new license hasn't been played offline yet, so this also resets the phase
    /// back to `licenseExpiration`.
    @discardableResult
    func updateLicenseExpiration(playbackID: String, claims: DRMTokenClaims) -> StoredAsset? {
        mutate(playbackID: playbackID) {
            $0.expireLicenseFrom = Date()
            $0.expirationPhase = .licenseExpiration
            $0.licenseExpirationSeconds = claims.licenseExpiration
            $0.playDurationSeconds = claims.playDuration
        }
    }
    
    public static func persistentKeyDirectory() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        return URL(fileURLWithPath: "mux-offline", relativeTo: baseURL)
    }

    
    // MARK: - Persistence

    private func persist() {
        do {
            try saveSnapshot(IndexSnapshot(version: Self.plistVersion, assets: assets))
        } catch {
            logger.error("[Mux-Offline] Failed to save index snapshot: \(error.localizedDescription)")
        }
    }

    private static func indexDirectoryURL() throws -> URL {
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
            PlayerSDK.shared.diagnosticsLogger.trace("Couldn't exclude index from backup: \(error)")
        }
        return dir
    }

    private static func indexFileURL() throws -> URL {
        try indexDirectoryURL().appendingPathComponent("index.plist", isDirectory: false)
    }

    private func saveSnapshot(_ snapshot: IndexSnapshot) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(snapshot)

        let url = try Self.indexFileURL()
        let tmp = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try data.write(to: tmp, options: .atomic)
        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } catch {
            try data.write(to: url)
        }
    }

    private static func loadSnapshot() throws -> IndexSnapshot? {
        let url = try indexFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(IndexSnapshot.self, from: data)
    }
}

#endif
