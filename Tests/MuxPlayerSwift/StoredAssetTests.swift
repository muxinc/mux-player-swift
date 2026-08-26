import XCTest

@testable import MuxPlayerSwift

final class StoredAssetTests: XCTestCase {

    private func makeStoredAsset(
        playbackID: String,
        ckcFilePath: String?,
        keyIdentifier: String?
    ) -> StoredAsset {
        var asset = StoredAsset.forNewDownload(
            playbackID: playbackID,
            options: DownloadOptions(readableTitle: "Test Asset"),
            drmClaims: nil
        )
        asset.ckcFilePath = ckcFilePath
        asset.keyIdentifier = keyIdentifier
        return asset
    }

    func testKeyIdentifierRoundTripsThroughPlist() throws {
        let identifier = "skd://fake.domain/?playbackId=abc-123&token=old~token"
        let asset = makeStoredAsset(
            playbackID: "abc-123",
            ckcFilePath: "abc-123-whatever.key",
            keyIdentifier: identifier
        )

        let encoded = try PropertyListEncoder().encode(asset)
        let decoded = try PropertyListDecoder().decode(StoredAsset.self, from: encoded)

        XCTAssertEqual(decoded.keyIdentifier, identifier)
    }

    // Index entries written by earlier SDK versions have no key identifier. They
    // still have to decode; they just aren't renewable.
    func testDecodesIndexEntryWithoutAKeyIdentifier() throws {
        let legacyEntry: [String: Any] = [
            "isComplete": true,
            "completedWithError": false,
            "playbackID": "abc-123",
            "readableTitle": "Legacy Asset",
            "ckcFilePath": "abc-123-whatever.key"
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: legacyEntry,
            format: .binary,
            options: 0
        )
        let decoded = try PropertyListDecoder().decode(StoredAsset.self, from: data)

        XCTAssertNil(decoded.keyIdentifier)
        XCTAssertEqual(decoded.ckcFilePath, "abc-123-whatever.key")
    }
}
