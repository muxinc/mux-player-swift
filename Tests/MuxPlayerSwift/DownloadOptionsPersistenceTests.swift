import XCTest

@testable import MuxPlayerSwift

final class DownloadOptionsPersistenceTests: XCTestCase {
    func testDownloadOptionsRoundTripThroughStoredAsset() {
        let posterData = Data([0x01, 0x02, 0x03])
        let downloadOptions = DownloadOptions(
            readableTitle: "Test Asset",
            posterData: posterData
        )

        let storedAsset = StoredAsset.forNewDownload(
            playbackID: "playback-id",
            options: downloadOptions
        )
        let restoredOptions = DownloadOptions(from: storedAsset)

        XCTAssertEqual(restoredOptions.readableTitle, "Test Asset")
        XCTAssertEqual(restoredOptions.posterData, posterData)
    }
}
