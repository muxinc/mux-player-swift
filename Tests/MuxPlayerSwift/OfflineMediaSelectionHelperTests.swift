import XCTest

@testable import MuxPlayerSwift

final class OfflineMediaSelectionHelperTests: XCTestCase {
    func testPreferredFirstUniqueSelectionsRemovesPreferredDuplicate() {
        let selections = OfflineMediaSelectionHelper.preferredFirstUniqueSelections(
            preferredSelection: "preferred",
            allSelections: ["preferred", "alternate-audio", "alternate-subtitle"],
            areEquivalent: ==
        )

        XCTAssertEqual(selections, ["preferred", "alternate-audio", "alternate-subtitle"])
    }

    func testPreferredFirstUniqueSelectionsPreservesPreferredWhenAllSelectionsDoNotContainIt() {
        let selections = OfflineMediaSelectionHelper.preferredFirstUniqueSelections(
            preferredSelection: "preferred",
            allSelections: ["alternate-audio", "alternate-subtitle"],
            areEquivalent: ==
        )

        XCTAssertEqual(selections, ["preferred", "alternate-audio", "alternate-subtitle"])
    }
}
