//
//  MuxPlayerSwiftExampleTests.swift
//  MuxPlayerSwiftExampleTests
//

import XCTest
@testable import MuxPlayerSwiftExample

final class MuxPlayerSwiftExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func launchAndWaitUntilInForeground(
        application: XCUIApplication
    ) throws {
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
        ]
        application.launch()

        let isRunningInForeground = application.wait(
            for: .runningForeground,
            timeout: 5.0
        )

        guard isRunningInForeground else {
            XCTFail("Failed to launch application")
            return
        }
    }

    func tapCell(
        cellIdentifier: String,
        waitFor viewIdentifier: String,
        application: XCUIApplication
    ) throws {
        let cellElement = application.cells.element(
            matching: .cell,
            identifier: cellIdentifier
        )

        guard cellElement.exists else {
            XCTFail("Failed to find cell element: \(cellIdentifier)")
            return
        }

        cellElement.tap()

        let viewElement = application.descendants(
            matching: .any
        ).element(
            matching: .any,
            identifier: viewIdentifier
        )

        let isViewElementOnScreen = viewElement.waitForExistence(
            timeout: 150.0
        )

        guard isViewElementOnScreen else {
            XCTFail("Failed to navigate to view element: \(viewIdentifier)")
            return
        }

        let isUnknown = application.wait(
            for: .unknown,
            timeout: 25.0
        )

        guard !isUnknown else {
            XCTFail("Application interrupted while playing video")
            return
        }
    }


    func testVideoOnDemandPlayerViewController() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "SinglePlayerExample",
            waitFor: "SinglePlayerView",
            application: application
        )
    }

    func testVideoOnDemandPlayerLayer() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "SinglePlayerLayerExample",
            waitFor: "SinglePlayerLayerView",
            application: application
        )
    }
}
