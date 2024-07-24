//
//  MonitorTests.swift
//

import AVKit
import Foundation
import XCTest

@testable import MuxPlayerSwift

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

class TestMonitor: Monitor {
    var monitoringRegistrations: [(MonitoringOptions, Bool)] = []

    override func setupMonitoring(
        playerViewController: AVPlayerViewController,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        super.setupMonitoring(
            playerViewController: playerViewController, 
            options: options,
            usingDRM: usingDRM
        )

        monitoringRegistrations.append(
            (options, usingDRM)
        )
    }

    override func setupMonitoring(
        playerLayer: AVPlayerLayer,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        super.setupMonitoring(
            playerLayer: playerLayer,
            options: options,
            usingDRM: usingDRM
        )

        monitoringRegistrations.append(
            (options, usingDRM)
        )
    }
}

class MonitorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PlayerSDK.shared.monitor.bindings.removeAll()
    }

    func testPlayerViewControllerMonitoringLifecycle() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerViewController = AVPlayerViewController(
            playbackID: "abc"
        )

        let monitor = PlayerSDK.shared.monitor

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
        PlayerSDK.shared.monitor = Monitor()

        let playerLayer = AVPlayerLayer(
            playbackID: "abc"
        )

        let monitor = PlayerSDK.shared.monitor

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
        PlayerSDK.shared.monitor = Monitor()

        let playerLayerBackedView = PlayerLayerBackedView()

        let preexistingPlayerLayer = try XCTUnwrap(
            playerLayerBackedView.layer as? AVPlayerLayer
        )

        preexistingPlayerLayer.prepare(
            playbackID: "abc"
        )

        let monitor = PlayerSDK.shared.monitor

        XCTAssertEqual(
            monitor.bindings.count,
            1
        )

        preexistingPlayerLayer.stopMonitoring()

        XCTAssertTrue(
            monitor.bindings.isEmpty
        )
    }

    func testDRMPlayerViewControllerMonitoring() throws {
        let testMonitor = TestMonitor()
        PlayerSDK.shared.monitor = testMonitor

        let playerViewController = AVPlayerViewController(
            playbackID: "abc",
            playbackOptions: PlaybackOptions(
                playbackToken: "abc",
                drmToken: "def"
            )
        )

        let playerBinding = try XCTUnwrap(
            testMonitor.bindings[ObjectIdentifier(playerViewController)]
        )
        XCTAssertNotNil(
            playerBinding
        )

        let registration = try XCTUnwrap(
            testMonitor.monitoringRegistrations.first
        )

        XCTAssertTrue(registration.1)

        testMonitor.monitoringRegistrations.removeAll()
    }

    func testDRMPlayerLayerMonitoring() throws {
        let testMonitor = TestMonitor()
        PlayerSDK.shared.monitor = testMonitor

        let playerLayer = AVPlayerLayer(
            playbackID: "abc",
            playbackOptions: PlaybackOptions(
                playbackToken: "abc",
                drmToken: "def"
            )
        )

        let playerBinding = try XCTUnwrap(
            testMonitor.bindings[ObjectIdentifier(playerLayer)]
        )
        XCTAssertNotNil(
            playerBinding
        )

        let registration = try XCTUnwrap(
            testMonitor.monitoringRegistrations.first
        )

        XCTAssertTrue(registration.1)
        testMonitor.monitoringRegistrations.removeAll()
    }

    func testDRMExistingPlayerLayerMonitoring() throws {
        let testMonitor = TestMonitor()
        PlayerSDK.shared.monitor = testMonitor

        let playerLayerBackedView = PlayerLayerBackedView()

        let preexistingPlayerLayer = try XCTUnwrap(
            playerLayerBackedView.layer as? AVPlayerLayer
        )

        preexistingPlayerLayer.prepare(
            playbackID: "abc",
            playbackOptions: PlaybackOptions(
                playbackToken: "def",
                drmToken: "ghi"
            )
        )

        let playerBinding = try XCTUnwrap(
            testMonitor.bindings[ObjectIdentifier(preexistingPlayerLayer)]
        )
        XCTAssertNotNil(
            playerBinding
        )

        let registration = try XCTUnwrap(
            testMonitor.monitoringRegistrations.first
        )

        XCTAssertTrue(registration.1)
        testMonitor.monitoringRegistrations.removeAll()
    }
}
