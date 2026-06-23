//
//  OnlineDRMLicenseCacheTests.swift
//  MuxPlayerSwift
//

import XCTest
@testable import MuxPlayerSwift

final class OnlineDRMLicenseCacheTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mux-online-drm-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
    }

    func testStoreThenHitReturnsLicense() async {
        let cache = OnlineDRMLicenseCache(directory: tempDir)
        let ckc = "license".data(using: .utf8)!

        await cache.store(playbackID: "pb", tokenFingerprint: "fp", ckc: ckc)
        let hit = await cache.cachedLicense(playbackID: "pb", tokenFingerprint: "fp")

        XCTAssertEqual(hit, ckc)
    }

    func testFingerprintMismatchMisses() async {
        let cache = OnlineDRMLicenseCache(directory: tempDir)
        await cache.store(playbackID: "pb", tokenFingerprint: "fp", ckc: "x".data(using: .utf8)!)

        let miss = await cache.cachedLicense(playbackID: "pb", tokenFingerprint: "different")

        XCTAssertNil(miss)
    }

    func testWithinTTLHits() async {
        var now = Date(timeIntervalSince1970: 1_000_000)
        let cache = OnlineDRMLicenseCache(directory: tempDir, ttl: 100, now: { now })
        let ckc = "x".data(using: .utf8)!
        await cache.store(playbackID: "pb", tokenFingerprint: "fp", ckc: ckc)

        now = now.addingTimeInterval(50) // still within TTL
        let hit = await cache.cachedLicense(playbackID: "pb", tokenFingerprint: "fp")

        XCTAssertEqual(hit, ckc)
    }

    func testExpiredEntryMisses() async {
        var now = Date(timeIntervalSince1970: 1_000_000)
        let cache = OnlineDRMLicenseCache(directory: tempDir, ttl: 100, now: { now })
        await cache.store(playbackID: "pb", tokenFingerprint: "fp", ckc: "x".data(using: .utf8)!)

        now = now.addingTimeInterval(101) // past TTL
        let miss = await cache.cachedLicense(playbackID: "pb", tokenFingerprint: "fp")

        XCTAssertNil(miss)
    }

    func testPersistsAcrossInstances() async {
        let ckc = "license".data(using: .utf8)!
        let cache1 = OnlineDRMLicenseCache(directory: tempDir)
        await cache1.store(playbackID: "pb", tokenFingerprint: "fp", ckc: ckc)

        // A fresh instance pointed at the same directory should load the entry.
        let cache2 = OnlineDRMLicenseCache(directory: tempDir)
        let hit = await cache2.cachedLicense(playbackID: "pb", tokenFingerprint: "fp")

        XCTAssertEqual(hit, ckc)
    }

    func testRemoveDiscardsEntry() async {
        let cache = OnlineDRMLicenseCache(directory: tempDir)
        await cache.store(playbackID: "pb", tokenFingerprint: "fp", ckc: "x".data(using: .utf8)!)

        await cache.remove(playbackID: "pb")
        let miss = await cache.cachedLicense(playbackID: "pb", tokenFingerprint: "fp")

        XCTAssertNil(miss)
    }
}
