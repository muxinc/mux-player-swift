//
//  MonitorTests.swift
//

import AVKit
import Foundation
import XCTest

@testable import MuxAVPlayerSDK

class MonitorTests: XCTestCase {

    func testPlayerViewControllerMonitoringLifecycle() throws {

        let playerViewController = AVPlayerViewController(
            playbackID: "abc"
        )

        let monitor = Monitor.shared

        XCTAssertEqual(
            monitor.bindings.count,
            1
        )

        playerViewController.stopMonitoring()

        XCTAssertTrue(
            monitor.bindings.isEmpty
        )

    }

    func testPlayerLayerMonitoringLifecycle() throws {

        let playerLayer = AVPlayerLayer(
            playbackID: "abc"
        )

        let monitor = Monitor.shared

        XCTAssertEqual(
            monitor.bindings.count,
            1
        )

        playerLayer.stopMonitoring()

        XCTAssertTrue(
            monitor.bindings.isEmpty
        )

    }

}
