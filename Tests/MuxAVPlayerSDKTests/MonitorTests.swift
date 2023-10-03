//
//  MonitorTests.swift
//

import AVKit
import Foundation
import XCTest

@testable import MuxAVPlayerSDK

class PlayerLayerBackedView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            (layer as? AVPlayerLayer)?.player
        }
        set {
            (layer as? AVPlayerLayer)?.player = newValue
        }
    }
}

class MonitorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Monitor.shared.bindings.removeAll()
    }

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

    func testExistingPlayerLayerMonitoringLifecycle() throws {

        let playerLayerBackedView = PlayerLayerBackedView()

        let preexistingPlayerLayer = try XCTUnwrap(
            playerLayerBackedView.layer as? AVPlayerLayer
        )

        preexistingPlayerLayer.prepare(
            playbackID: "abc"
        )

        let monitor = Monitor.shared

        XCTAssertEqual(
            monitor.bindings.count,
            1
        )

        preexistingPlayerLayer.stopMonitoring()

        XCTAssertTrue(
            monitor.bindings.isEmpty
        )
    }

}
