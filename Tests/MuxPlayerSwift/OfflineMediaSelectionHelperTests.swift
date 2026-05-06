import XCTest

@testable import MuxPlayerSwift

final class OfflineMediaSelectionHelperTests: XCTestCase {
    func testSelectedCachedOptionReturnsPreferredOptionWhenCached() {
        let selectedOption = OfflineMediaSelectionHelper.selectedCachedOption(
            preferredOption: "fr",
            cachedOptions: ["en", "fr", "de"],
            fallbackToFirstCachedOption: true
        )

        XCTAssertEqual(selectedOption, "fr")
    }

    func testSelectedCachedOptionFallsBackToFirstCachedOptionWhenAllowed() {
        let selectedOption = OfflineMediaSelectionHelper.selectedCachedOption(
            preferredOption: "fr",
            cachedOptions: ["en", "de"],
            fallbackToFirstCachedOption: true
        )

        XCTAssertEqual(selectedOption, "en")
    }

    func testSelectedCachedOptionFallsBackToFirstCachedOptionWhenPreferredOptionIsNil() {
        let selectedOption = OfflineMediaSelectionHelper.selectedCachedOption(
            preferredOption: nil as String?,
            cachedOptions: ["en", "de"],
            fallbackToFirstCachedOption: true
        )

        XCTAssertEqual(selectedOption, "en")
    }

    func testSelectedCachedOptionReturnsNilWhenFallbackIsDisabled() {
        let selectedOption = OfflineMediaSelectionHelper.selectedCachedOption(
            preferredOption: "fr",
            cachedOptions: ["en", "de"],
            fallbackToFirstCachedOption: false
        )

        XCTAssertNil(selectedOption)
    }

    func testSelectedCachedOptionReturnsNilWhenPreferredOptionIsNilAndFallbackIsDisabled() {
        let selectedOption = OfflineMediaSelectionHelper.selectedCachedOption(
            preferredOption: nil as String?,
            cachedOptions: ["en", "de"],
            fallbackToFirstCachedOption: false
        )

        XCTAssertNil(selectedOption)
    }

    func testSelectedCachedOptionReturnsNilWhenNoOptionsAreCached() {
        let selectedOption = OfflineMediaSelectionHelper.selectedCachedOption(
            preferredOption: nil as String?,
            cachedOptions: [],
            fallbackToFirstCachedOption: true
        )

        XCTAssertNil(selectedOption)
    }
}
