import XCTest

@testable import MuxPlayerSwift

final class OfflineMediaSelectionTests: XCTestCase {
    func testDownloadOptionsPersistRequestedMediaSelectionPolicy() {
        let requestedOption = OfflineMediaOption(
            id: "audio-option",
            displayName: "English",
            type: .audio,
            extendedLanguageTag: "en"
        )
        let downloadOptions = DownloadOptions(
            readableTitle: "Test Asset",
            mediaSelectionPolicy: .options([requestedOption])
        )

        let storedAsset = StoredAsset.forNewDownload(
            playbackID: "playback-id",
            options: downloadOptions
        )
        let restoredOptions = DownloadOptions(from: storedAsset)

        XCTAssertEqual(restoredOptions.mediaSelectionPolicy, .options([requestedOption]))
    }

    func testMissingStoredMediaSelectionPolicyRestoresAutomaticPolicy() {
        let storedAsset = StoredAsset(
            isComplete: false,
            completedWithError: false,
            playbackID: "playback-id",
            localPath: nil,
            readableTitle: "Test Asset",
            posterDataBase64: nil,
            mediaSelectionPolicy: nil,
            ckcFilePath: nil,
            redownloadExpiration: nil,
            expireLicenseFrom: nil,
            expirationPhase: nil,
            licenseExpirationSeconds: nil,
            playDurationSeconds: nil
        )

        let restoredOptions = DownloadOptions(from: storedAsset)

        XCTAssertEqual(restoredOptions.mediaSelectionPolicy, .automatic)
    }

    func testPrimaryLanguageSubtagNormalizesCommonTags() {
        XCTAssertEqual(OfflineMediaSelectionResolver.primaryLanguageSubtag(for: "en-US"), "en")
        XCTAssertEqual(OfflineMediaSelectionResolver.primaryLanguageSubtag(for: "pt_BR"), "pt")
        XCTAssertEqual(OfflineMediaSelectionResolver.primaryLanguageSubtag(for: "  ES-419  "), "es")
        XCTAssertNil(OfflineMediaSelectionResolver.primaryLanguageSubtag(for: nil))
    }
}
