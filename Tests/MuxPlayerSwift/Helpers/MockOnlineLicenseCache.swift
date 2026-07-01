import Foundation
@testable import MuxPlayerSwift

/// In-memory ``OnlineLicenseCaching`` for tests, with call recording.
class MockOnlineLicenseCache: OnlineLicenseCaching {

    /// Pre-seed to simulate cache hits: playbackID -> (license, fingerprint).
    /// A lookup only hits when the fingerprint matches.
    var cached: [String: (data: Data, fingerprint: String)] = [:]

    var storedCalls: [(playbackID: String, fingerprint: String, ckc: Data)] = []
    var removedCalls: [String] = []

    func cachedLicense(playbackID: String, tokenFingerprint: String) async -> Data? {
        guard let entry = cached[playbackID], entry.fingerprint == tokenFingerprint else {
            return nil
        }
        return entry.data
    }

    func store(playbackID: String, tokenFingerprint: String, ckc: Data) async {
        storedCalls.append((playbackID, tokenFingerprint, ckc))
        cached[playbackID] = (ckc, tokenFingerprint)
    }

    func remove(playbackID: String) async {
        removedCalls.append(playbackID)
        cached[playbackID] = nil
    }
}
