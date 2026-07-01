//
//  OnlineDRMLicenseCache.swift
//  MuxPlayerSwift
//
//  Short-term, on-disk cache of the persistable FairPlay licenses (CKCs) Mux
//  issues for *online* playback, so repeat plays reuse the license instead of
//  re-hitting the license server (a cost optimization).
//
//  Kept separate from the offline download key store: these aren't downloaded
//  assets — they expire on a fixed short clock and live under Caches.
//

import Foundation
import os

// MARK: - OnlineLicenseCaching

/// Abstraction over the online license cache so it can be mocked in tests.
protocol OnlineLicenseCaching {
    /// A cached license for the playbackID, if present, matching `tokenFingerprint` and unexpired.
    func cachedLicense(playbackID: String, tokenFingerprint: String) async -> Data?
    func store(playbackID: String, tokenFingerprint: String, ckc: Data) async
    func remove(playbackID: String) async
}

// MARK: - OnlineDRMLicenseCache

actor OnlineDRMLicenseCache: OnlineLicenseCaching {

    static let shared = OnlineDRMLicenseCache()

    /// Mux's online licenses last ~24h and FairPlay gives no way to read a CKC's
    /// true expiry, so we treat a cached license as valid for this long — kept
    /// just under 24h as a safety margin.
    static let defaultTTL: TimeInterval = 23 * 60 * 60

    private static let snapshotVersion = 1

    private struct Entry: Codable {
        let fileName: String
        let tokenFingerprint: String
        let fetchedAt: Date
    }

    private struct Snapshot: Codable {
        let version: Int
        let entries: [String: Entry]
    }

    #if DEBUG
    private let logger = Logger(OSLog(subsystem: "com.mux.player", category: "CK"))
    #else
    private let logger = Logger(.disabled)
    #endif

    private let directory: URL?
    private let ttl: TimeInterval
    private let now: () -> Date

    private var entries: [String: Entry]
    private var loaded = false

    /// `directory` and `now` are test injection points; `ttl` is how long a
    /// cached license stays valid after fetch.
    init(
        directory: URL? = nil,
        ttl: TimeInterval = OnlineDRMLicenseCache.defaultTTL,
        now: @escaping () -> Date = { Date() }
    ) {
        self.directory = directory
        self.ttl = ttl
        self.now = now
        self.entries = [:]
    }

    // MARK: OnlineLicenseCaching

    func cachedLicense(playbackID: String, tokenFingerprint: String) async -> Data? {
        loadIfNeeded()

        guard let entry = entries[playbackID] else {
            return nil
        }

        // A new token for the same playbackID means entitlements may have
        // changed; treat the cached license as invalid and re-fetch.
        guard entry.tokenFingerprint == tokenFingerprint else {
            logger.debug("[Mux-Online-DRM] token changed for \(playbackID, privacy: .public); invalidating cached license")
            discard(playbackID: playbackID)
            return nil
        }

        guard now() < entry.fetchedAt.addingTimeInterval(ttl) else {
            logger.debug("[Mux-Online-DRM] cached license expired for \(playbackID, privacy: .public)")
            discard(playbackID: playbackID)
            return nil
        }

        guard let dir = try? cacheDirectory() else { return nil }
        let fileURL = dir.appendingPathComponent(entry.fileName)
        guard let data = FileManager.default.contents(atPath: fileURL.path), !data.isEmpty else {
            logger.warning("[Mux-Online-DRM] cached license file missing for \(playbackID, privacy: .public)")
            discard(playbackID: playbackID)
            return nil
        }

        logger.debug("[Mux-Online-DRM] serving cached license for \(playbackID, privacy: .public)")
        return data
    }

    func store(playbackID: String, tokenFingerprint: String, ckc: Data) async {
        loadIfNeeded()

        guard let dir = try? cacheDirectory() else {
            logger.warning("[Mux-Online-DRM] couldn't resolve cache directory; not caching \(playbackID, privacy: .public)")
            return
        }

        let fileName = "\(sanitized(playbackID)).ckc"
        let fileURL = dir.appendingPathComponent(fileName)
        do {
            try ckc.write(to: fileURL, options: .atomic)
        } catch {
            logger.warning("[Mux-Online-DRM] failed to write cached license for \(playbackID, privacy: .public): \(error.localizedDescription)")
            return
        }

        entries[playbackID] = Entry(
            fileName: fileName,
            tokenFingerprint: tokenFingerprint,
            fetchedAt: now()
        )
        persist()
        logger.debug("[Mux-Online-DRM] cached license for \(playbackID, privacy: .public)")
    }

    func remove(playbackID: String) async {
        loadIfNeeded()
        discard(playbackID: playbackID)
    }

    // MARK: Internals

    /// Drops any entries whose TTL has elapsed, deleting their files. Runs once
    /// per process after the index is loaded, to keep disk usage bounded.
    private func purgeExpired() {
        let cutoff = now()
        let expired = entries
            .filter { cutoff >= $0.value.fetchedAt.addingTimeInterval(ttl) }
            .map(\.key)
        for playbackID in expired {
            discard(playbackID: playbackID)
        }
    }

    private func discard(playbackID: String) {
        if let entry = entries.removeValue(forKey: playbackID),
           let dir = try? cacheDirectory() {
            let fileURL = dir.appendingPathComponent(entry.fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        persist()
    }

    private func sanitized(_ playbackID: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return String(playbackID.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }

    private func cacheDirectory() throws -> URL {
        if let directory {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
        let fileManager = FileManager.default
        let base = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        var dir = base.appendingPathComponent("mux-online-drm", isDirectory: true)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        return dir
    }

    private func indexFileURL() throws -> URL {
        try cacheDirectory().appendingPathComponent("index.plist", isDirectory: false)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        do {
            let url = try indexFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let snapshot = try PropertyListDecoder().decode(Snapshot.self, from: data)
            entries = snapshot.entries
        } catch {
            logger.error("[Mux-Online-DRM] failed to load cache index: \(error.localizedDescription)")
            entries = [:]
        }
        purgeExpired()
    }

    private func persist() {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let data = try encoder.encode(Snapshot(version: Self.snapshotVersion, entries: entries))
            try data.write(to: try indexFileURL(), options: .atomic)
        } catch {
            logger.error("[Mux-Online-DRM] failed to persist cache index: \(error.localizedDescription)")
        }
    }
}
