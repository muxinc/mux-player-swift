//
//  MuxPlayerSwiftExampleUITests.swift
//  MuxPlayerSwiftExampleUITests
//

import XCTest

final class MuxPlayerSwiftExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
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
        let cellElement = application.descendants(
            matching: .any
        ).element(
            matching: .any,
            identifier: cellIdentifier
        )

        guard cellElement.waitForExistence(timeout: 5.0) else {
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

    func testContainerPlayer() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "ContainerPlayerRow",
            waitFor: "ContainerPlayerView",
            application: application
        )
    }

    func testSinglePlayer() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "SinglePlayerRow",
            waitFor: "SinglePlayerView",
            application: application
        )
    }

    func testSmartCachePlayer() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "SmartCachePlayerRow",
            waitFor: "SmartCachePlayerView",
            application: application
        )
    }

    func testSinglePlayerLayer() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "SinglePlayerLayerRow",
            waitFor: "SinglePlayerLayerView",
            application: application
        )
    }

    func testDRMPlayer() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "DRMPlayerRow",
            waitFor: "DRMPlayerView",
            application: application
        )
    }
}
