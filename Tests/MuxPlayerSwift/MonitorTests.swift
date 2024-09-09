//
//  MonitorTests.swift
//

import AVKit
import Foundation
import XCTest

import MUXSDKStats

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
        playbackID: String,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        super.setupMonitoring(
            playerViewController: playerViewController, 
            playbackID: playbackID,
            options: options,
            usingDRM: usingDRM
        )

        monitoringRegistrations.append(
            (options, usingDRM)
        )
    }

    override func setupMonitoring(
        playerLayer: AVPlayerLayer,
        playbackID: String,
        options: MonitoringOptions,
        usingDRM: Bool = false
    ) {
        super.setupMonitoring(
            playerLayer: playerLayer, 
            playbackID: playbackID,
            options: options,
            usingDRM: usingDRM
        )

        monitoringRegistrations.append(
            (options, usingDRM)
        )
    }
}

class TestPlayerObservationContext: PlayerObservationContext {

    struct MonitorCall {
        // AVPlayerViewController or AVPlayerLayer or AVPlayer
        // Only included to validate pointer equality, for
        // which NSObject suffices
        let player: NSObject
        let playerName: String
        let customerData: MUXSDKCustomerData
        let automaticErrorTracking: Bool
    }

    var monitorCalls: [MonitorCall] = []

    override func monitorAVPlayerViewController(
        _ player: AVPlayerViewController,
        withPlayerName name: String,
        customerData: MUXSDKCustomerData,
        automaticErrorTracking: Bool
    ) -> MUXSDKPlayerBinding? {
        
        monitorCalls.append(
            MonitorCall(
                player: player,
                playerName: name,
                customerData: customerData,
                automaticErrorTracking: automaticErrorTracking
            )
        )

        // In its current state this test class is only
        // useful for validating Mux Data inputs.
        //
        // This needs to return a non-nil value in order to
        // validate side effects in this SDK.
        return nil
    }

    override func monitorAVPlayerLayer(
        _ player: AVPlayerLayer,
        withPlayerName name: String,
        customerData: MUXSDKCustomerData,
        automaticErrorTracking: Bool
    ) -> MUXSDKPlayerBinding? {

        monitorCalls.append(
            MonitorCall(
                player: player,
                playerName: name,
                customerData: customerData,
                automaticErrorTracking: automaticErrorTracking
            )
        )

        // In its current state this test class is only
        // useful for validating Mux Data inputs.
        //
        // This needs to return a non-nil value in order to
        // validate side effects in this SDK.
        return nil
//        return MUXSDKPlayerBinding(
//            name: "",
//            andSoftware: ""
//        )
    }

    override func destroyPlayer(
        _ name: String
    ) {

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

    func testInitializedPlayerViewControllerKVORegistrationNonDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerViewController = AVPlayerViewController(
            playbackID: "abc123"
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerViewController.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            1
        )

        let playerViewControllerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerViewControllerObjectIdentifier,
            ObjectIdentifier(playerViewController)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerViewController: playerViewController
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testInitializedPlayerLayerKVORegistrationNonDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerLayer = AVPlayerLayer(
            playbackID: "abc123"
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerLayer.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            1
        )

        let playerLayerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerLayerObjectIdentifier,
            ObjectIdentifier(playerLayer)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerLayer: playerLayer
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testPreexistingPlayerViewControllerKVORegistrationNonDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerViewController = AVPlayerViewController()
        playerViewController.prepare(
            playbackID: "abc123"
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerViewController.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            1
        )

        let playerViewControllerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerViewControllerObjectIdentifier,
            ObjectIdentifier(playerViewController)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerViewController: playerViewController
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testPreexistingPlayerLayerKVORegistrationNonDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerLayer = AVPlayerLayer()
        playerLayer.prepare(
            playbackID: "abc123"
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerLayer.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            1
        )

        let playerLayerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerLayerObjectIdentifier,
            ObjectIdentifier(playerLayer)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerLayer: playerLayer
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testInitializedPlayerViewControllerKVORegistrationDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerViewController = AVPlayerViewController(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                playbackToken: "def456",
                drmToken: "ghi789"
            )
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerViewController.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            2
        )

        let playerViewControllerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerViewControllerObjectIdentifier,
            ObjectIdentifier(playerViewController)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerViewController: playerViewController
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testInitializedPlayerLayerKVORegistrationDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerLayer = AVPlayerLayer(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                playbackToken: "def456",
                drmToken: "ghi789"
            )
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerLayer.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            2
        )

        let playerLayerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerLayerObjectIdentifier,
            ObjectIdentifier(playerLayer)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerLayer: playerLayer
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testPreexistingPlayerViewControllerKVORegistrationDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerViewController = AVPlayerViewController()
        playerViewController.prepare(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                playbackToken: "def456",
                drmToken: "ghi789"
            )
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerViewController.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            2
        )

        let playerViewControllerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerViewControllerObjectIdentifier,
            ObjectIdentifier(playerViewController)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerViewController: playerViewController
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testPreexistingPlayerLayerKVORegistrationDRM() throws {
        PlayerSDK.shared.monitor = Monitor()

        let playerLayer = AVPlayerLayer()
        playerLayer.prepare(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                playbackToken: "def456",
                drmToken: "ghi789"
            )
        )

        XCTAssertEqual(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations
                .count,
            1
        )

        let player = try XCTUnwrap(
            playerLayer.player
        )

        let observations = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            observations.count,
            2
        )

        let playerLayerObjectIdentifier = try XCTUnwrap(
            PlayerSDK
                .shared
                .monitor
                .playerObjectIdentifiersToBindingReferenceObjectIdentifier[
                    ObjectIdentifier(player)
                ]
        )

        XCTAssertEqual(
            playerLayerObjectIdentifier,
            ObjectIdentifier(playerLayer)
        )

        PlayerSDK.shared.monitor.tearDownMonitoring(
            playerLayer: playerLayer
        )

        XCTAssertNil(
            PlayerSDK
                .shared
                .monitor
                .keyValueObservation
                .observations[
                    ObjectIdentifier(player)
                ]
        )
    }

    func testPlayerMonitoringInputs_PlayerViewController_NonDRM() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let playerViewController = AVPlayerViewController(
            playbackID: "abc123"
        )

        let monitorCall = try XCTUnwrap(
            testPlayerObservationContext.monitorCalls.first
        )

        XCTAssertEqual(
            monitorCall.player,
            playerViewController
        )

        XCTAssertTrue(monitorCall.automaticErrorTracking)

        let playerSoftwareName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareName
        )

        XCTAssertEqual(
            playerSoftwareName,
            "MuxPlayerSwiftAVPlayerViewController"
        )


        let playerSoftwareVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareVersion
        )

        XCTAssertEqual(
            playerSoftwareVersion,
            SemanticVersion.versionString
        )
    }

    func testPlayerMonitoringInputs_PlayerViewController_NonDRM_CustomEnvironmentKey() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let playerViewController = AVPlayerViewController(
            playbackID: "abc123",
            monitoringOptions: MonitoringOptions(
                environmentKey: "xyz321",
                playerName: "test-player-name"
            )
        )

        let monitorCall = try XCTUnwrap(
            testPlayerObservationContext.monitorCalls.first
        )

        XCTAssertEqual(
            monitorCall.player,
            playerViewController
        )

        XCTAssertEqual(
            monitorCall.playerName,
            "test-player-name"
        )

        XCTAssertTrue(monitorCall.automaticErrorTracking)

        let environmentKey = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.environmentKey
        )

        XCTAssertEqual(
            environmentKey,
            "xyz321"
        )

        let playerSoftwareName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareName
        )

        XCTAssertEqual(
            playerSoftwareName,
            "MuxPlayerSwiftAVPlayerViewController"
        )


        let playerSoftwareVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareVersion
        )

        XCTAssertEqual(
            playerSoftwareVersion,
            SemanticVersion.versionString
        )
    }

    func testPlayerMonitoringInputs_PlayerLayer_NonDRM() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let playerLayer = AVPlayerLayer(
            playbackID: "abc123"
        )

        let monitorCall = try XCTUnwrap(
            testPlayerObservationContext.monitorCalls.first
        )

        XCTAssertEqual(
            monitorCall.player,
            playerLayer
        )

        XCTAssertTrue(monitorCall.automaticErrorTracking)

        let playerSoftwareName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareName
        )

        XCTAssertEqual(
            playerSoftwareName,
            "MuxPlayerSwiftAVPlayerLayer"
        )


        let playerSoftwareVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareVersion
        )

        XCTAssertEqual(
            playerSoftwareVersion,
            SemanticVersion.versionString
        )
    }

    func testPlayerMonitoringInputs_PlayerLayer_NonDRM_CustomEnvironmentKey() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let playerLayer = AVPlayerLayer(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(),
            monitoringOptions: MonitoringOptions(
                environmentKey: "xyz321",
                playerName: "test-player-name"
            )
        )

        let monitorCall = try XCTUnwrap(
            testPlayerObservationContext.monitorCalls.first
        )

        XCTAssertEqual(
            monitorCall.player,
            playerLayer
        )

        XCTAssertEqual(
            monitorCall.playerName,
            "test-player-name"
        )

        XCTAssertTrue(monitorCall.automaticErrorTracking)

        let environmentKey = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.environmentKey
        )

        XCTAssertEqual(
            environmentKey,
            "xyz321"
        )

        XCTAssertTrue(monitorCall.automaticErrorTracking)

        let playerSoftwareName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareName
        )

        XCTAssertEqual(
            playerSoftwareName,
            "MuxPlayerSwiftAVPlayerLayer"
        )


        let playerSoftwareVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareVersion
        )

        XCTAssertEqual(
            playerSoftwareVersion,
            SemanticVersion.versionString
        )
    }

    func testPlayerMonitoringInputsPlayerViewControllerDRM() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let playerViewController = AVPlayerViewController(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                playbackToken: "def456",
                drmToken: "ghi789"
            )
        )

        let monitorCall = try XCTUnwrap(
            testPlayerObservationContext.monitorCalls.first
        )

        XCTAssertEqual(
            monitorCall.player,
            playerViewController
        )
    }

    func testPlayerMonitoringInputsPlayerLayerDRM() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let playerLayer = AVPlayerLayer(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                playbackToken: "def456",
                drmToken: "ghi789"
            )
        )

        let monitorCall = try XCTUnwrap(
            testPlayerObservationContext.monitorCalls.first
        )

        XCTAssertEqual(
            monitorCall.player,
            playerLayer
        )
    }

//    func testPlayerItemUpdates() throws {
//        PlayerSDK.shared.monitor = Monitor()
//
//        let playerLayer = AVPlayerLayer(
//            playbackID: "abc123",
//            playbackOptions: PlaybackOptions(
//                playbackToken: "def456",
//                drmToken: "ghi789"
//            )
//        )
//
//        
//
//        playerLayer.prepare(
//            playbackID: "jkl123",
//            playbackOptions: PlaybackOptions(
//                playbackToken: "mno456",
//                drmToken: "pqr789"
//            )
//        )
//
//
//
//    }
}
