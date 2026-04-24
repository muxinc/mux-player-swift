import Foundation
@testable import MuxPlayerSwift

class MockPersistedKeyStore: PersistedKeyStore {

    var persistedKeys: [String: Data] = [:]
    var savedKeys: [(playbackID: String, identifier: String, data: Data)] = []
    var updatedPhases: [(playbackID: String, phase: ExpirationPhase)] = []
    var findError: Error?

    func findPersistedContentKey(playbackID: String) async throws -> Data? {
        if let findError { throw findError }
        return persistedKeys[playbackID]
    }

    func savePersistedContentKey(playbackID: String, identifier: String, contentKeyData: Data) async throws {
        savedKeys.append((playbackID, identifier, contentKeyData))
    }

    func updateExpirationPhase(playbackID: String, phase: ExpirationPhase) async {
        updatedPhases.append((playbackID, phase))
    }
}
