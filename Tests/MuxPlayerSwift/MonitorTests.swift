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

    func validate(
        context: TestPlayerObservationContext,
        monitorCallIndex: Int = 0,
        playerReference: NSObject,
        automaticErrorTracking: Bool
    ) {
        let monitorCall = context.monitorCalls[monitorCallIndex]

        // Validate player reference
        XCTAssertEqual(
            monitorCall.player,
            playerReference
        )

        // Validate automatic error tracking
        XCTAssertEqual(
            monitorCall.automaticErrorTracking,
            automaticErrorTracking
        )
    }

    func validate(
        context: TestPlayerObservationContext,
        monitorCallIndex: Int = 0,
        playerReference: NSObject,
        automaticErrorTracking: Bool,
        expectedPlayerSoftwareName: String,
        expectedPlayerSoftwareVersion: String
    ) throws {
        let monitorCall = context.monitorCalls[monitorCallIndex]

        // Validate player reference
        XCTAssertEqual(
            monitorCall.player,
            playerReference
        )

        // Validate automatic error tracking
        XCTAssertEqual(
            monitorCall.automaticErrorTracking,
            automaticErrorTracking
        )

        // Validate player software name and version
        let playerSoftwareName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareName
        )
        XCTAssertEqual(
            playerSoftwareName,
            expectedPlayerSoftwareName
        )

        let playerSoftwareVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareVersion
        )
        XCTAssertEqual(
            playerSoftwareVersion,
            expectedPlayerSoftwareVersion
        )
    }

    func validate(
        context: TestPlayerObservationContext,
        monitorCallIndex: Int = 0,
        expectedPlayerName: String
    ) throws {
        let monitorCall = context.monitorCalls[monitorCallIndex]

        // Validate player name (used by Mux Data as key)
        XCTAssertEqual(
            monitorCall.playerName,
            expectedPlayerName
        )
    }

    func validate(
        context: TestPlayerObservationContext,
        monitorCallIndex: Int = 0,
        expectedEnvironmentKey: String
    ) throws {
        let monitorCall = context.monitorCalls[monitorCallIndex]

        // Validate environment key to match custom value
        let environmentKey = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.environmentKey
        )
        XCTAssertEqual(
            environmentKey,
            expectedEnvironmentKey
        )
    }

    func validate(
        context: TestPlayerObservationContext,
        monitorCallIndex: Int = 0,
        expectedViewDRMType: String
    ) throws {
        let monitorCall = context.monitorCalls[monitorCallIndex]

        // Validate DRM type
        let viewDRMType = try XCTUnwrap(
            monitorCall.customerData.customerViewData?.viewDrmType
        )
        XCTAssertEqual(
            viewDRMType,
            "fairplay"
        )
    }

    func validate(
        context: TestPlayerObservationContext,
        monitorCallIndex: Int = 0,
        playerReference: NSObject,
        providedCustomerData: MUXSDKCustomerData,
        expectedPlayerSoftwareName: String,
        expectedPlayerSoftwareVersion: String,
        expectedEnvironmentKey: String,
        expectedPlayerName: String,
        expectedPlayerVersion: String,
        expectedVideoTitle: String,
        expectedSessionID: String,
        expectedViewerApplicationName: String,
        expectedCustomData1: String
    ) throws {
        let monitorCall = context.monitorCalls[monitorCallIndex]

        XCTAssertNotEqual(
            providedCustomerData,
            monitorCall.customerData
        )

        XCTAssertNotEqual(
            providedCustomerData.customerPlayerData,
            monitorCall.customerData.customerPlayerData
        )

        // Validate no DRM type set
        XCTAssertNil(
            monitorCall.customerData.customerViewData?.viewDrmType
        )

        // Validate player software name and version
        let playerSoftwareName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareName
        )
        XCTAssertEqual(
            playerSoftwareName,
            expectedPlayerSoftwareName
        )

        let playerSoftwareVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerSoftwareVersion
        )
        XCTAssertEqual(
            playerSoftwareVersion,
            expectedPlayerSoftwareVersion
        )

        // Validate custom dimensions passed through
        let environmentKey = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.environmentKey
        )
        XCTAssertEqual(
            environmentKey,
            expectedEnvironmentKey
        )

        let playerName = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerName
        )
        XCTAssertEqual(
            playerName,
            expectedPlayerName
        )

        let playerVersion = try XCTUnwrap(
            monitorCall.customerData.customerPlayerData?.playerVersion
        )
        XCTAssertEqual(
            playerVersion,
            expectedPlayerVersion
        )

        let videoTitle = try XCTUnwrap(
            monitorCall.customerData.customerVideoData?.videoTitle
        )
        XCTAssertEqual(
            videoTitle,
            expectedVideoTitle
        )

        let videoSessionID = try XCTUnwrap(
            monitorCall.customerData.customerViewData?.viewSessionId
        )
        XCTAssertEqual(
            videoSessionID,
            expectedSessionID
        )

        let viewerApplicationName = try XCTUnwrap(
            monitorCall.customerData.customerViewerData?.viewerApplicationName
        )
        XCTAssertEqual(
            viewerApplicationName,
            expectedViewerApplicationName
        )

        let customData1 = try XCTUnwrap(
            monitorCall.customerData.customData?.customData1
        )
        XCTAssertEqual(
            customData1,
            expectedCustomData1
        )
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

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerViewController,
            automaticErrorTracking: true,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerViewController",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
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

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerViewController,
            automaticErrorTracking: true,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerViewController",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
        )

        try validate(
            context: testPlayerObservationContext,
            expectedPlayerName: "test-player-name"
        )

        try validate(
            context: testPlayerObservationContext,
            expectedEnvironmentKey: "xyz321"
        )
    }

    func testPlayerMonitoringInputs_PlayerViewController_NonDRM_CustomCustomerData() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let customerPlayerData = MUXSDKCustomerPlayerData()
        customerPlayerData.environmentKey = "wuv654"
        customerPlayerData.experimentName = "experiment-42"
        customerPlayerData.playerName = "my-shiny-player"
        customerPlayerData.playerVersion = "v1.0.0"

        let customerVideoData = MUXSDKCustomerVideoData()
        customerVideoData.videoTitle = "my-video"

        let customerViewData = MUXSDKCustomerViewData()
        customerViewData.viewSessionId = "abcdefghi"

        let customData = MUXSDKCustomData()
        customData.customData1 = "baz"

        let customViewerData = MUXSDKCustomerViewerData()
        customViewerData.viewerApplicationName = "FooBarApp"

        let customerData = try XCTUnwrap(
            MUXSDKCustomerData(
                customerPlayerData: customerPlayerData,
                videoData: customerVideoData,
                viewData: customerViewData,
                customData: customData,
                viewerData: customViewerData
            )
        )

        let playerViewController = AVPlayerViewController(
            playbackID: "abc123",
            monitoringOptions: MonitoringOptions(
                customerData: customerData,
                playerName: "test-player-name-custom-data"
            )
        )

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerViewController,
            providedCustomerData: customerData,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerViewController",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString,
            expectedEnvironmentKey: "wuv654",
            expectedPlayerName: "my-shiny-player",
            expectedPlayerVersion: "v1.0.0",
            expectedVideoTitle: "my-video",
            expectedSessionID: "abcdefghi",
            expectedViewerApplicationName: "FooBarApp",
            expectedCustomData1: "baz"
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

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerLayer,
            automaticErrorTracking: true,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerLayer",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
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

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerLayer,
            automaticErrorTracking: true,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerLayer",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
        )

        try validate(
            context: testPlayerObservationContext,
            expectedPlayerName: "test-player-name"
        )

        try validate(
            context: testPlayerObservationContext,
            expectedEnvironmentKey: "xyz321"
        )
    }

    func testPlayerMonitoringInputs_PlayerLayer_NonDRM_CustomCustomerData() throws {
        let testPlayerObservationContext = TestPlayerObservationContext()
        let testMonitor = Monitor(
            playerObservationContext: testPlayerObservationContext
        )
        PlayerSDK.shared.monitor = testMonitor

        let customerPlayerData = MUXSDKCustomerPlayerData()
        customerPlayerData.environmentKey = "wuv654"
        customerPlayerData.experimentName = "experiment-42"
        customerPlayerData.playerName = "my-shiny-player"
        customerPlayerData.playerVersion = "v1.0.0"

        let customerVideoData = MUXSDKCustomerVideoData()
        customerVideoData.videoTitle = "my-video"

        let customerViewData = MUXSDKCustomerViewData()
        customerViewData.viewSessionId = "abcdefghi"

        let customData = MUXSDKCustomData()
        customData.customData1 = "baz"

        let customViewerData = MUXSDKCustomerViewerData()
        customViewerData.viewerApplicationName = "FooBarApp"

        let customerData = try XCTUnwrap(
            MUXSDKCustomerData(
                customerPlayerData: customerPlayerData,
                videoData: customerVideoData,
                viewData: customerViewData,
                customData: customData,
                viewerData: customViewerData
            )
        )

        let playerLayer = AVPlayerLayer(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(),
            monitoringOptions: MonitoringOptions(
                customerData: customerData,
                playerName: "test-player-name-custom-data"
            )
        )

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerLayer,
            providedCustomerData: customerData,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerLayer",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString,
            expectedEnvironmentKey: "wuv654",
            expectedPlayerName: "my-shiny-player",
            expectedPlayerVersion: "v1.0.0",
            expectedVideoTitle: "my-video",
            expectedSessionID: "abcdefghi",
            expectedViewerApplicationName: "FooBarApp",
            expectedCustomData1: "baz"
        )
    }

    func testPlayerMonitoringInputs_PlayerViewController_DRM() throws {
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

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerViewController,
            automaticErrorTracking: false,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerViewController",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
        )

        try validate(
            context: testPlayerObservationContext,
            expectedViewDRMType: "fairplay"
        )
    }

    func testPlayerMonitoringInputs_PlayerViewController_DRM_CustomEnvironmentKey() throws {
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
            ),
            monitoringOptions: MonitoringOptions(
                environmentKey: "xyz321",
                playerName: "test-player-name"
            )
        )

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerViewController,
            automaticErrorTracking: false,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerViewController",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
        )

        try validate(
            context: testPlayerObservationContext,
            expectedPlayerName: "test-player-name"
        )

        try validate(
            context: testPlayerObservationContext,
            expectedEnvironmentKey: "xyz321"
        )

        try validate(
            context: testPlayerObservationContext,
            expectedViewDRMType: "fairplay"
        )
    }

    func testPlayerMonitoringInputs_PlayerLayer_DRM() throws {
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

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerLayer,
            automaticErrorTracking: false,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerLayer",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
        )

        try validate(
            context: testPlayerObservationContext,
            expectedViewDRMType: "fairplay"
        )
    }

    func testPlayerMonitoringInputs_PlayerLayer_DRM_CustomEnvironmentKey() throws {
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
            ),
            monitoringOptions: MonitoringOptions(
                environmentKey: "xyz321",
                playerName: "test-player-name"
            )
        )

        try validate(
            context: testPlayerObservationContext,
            playerReference: playerLayer,
            automaticErrorTracking: false,
            expectedPlayerSoftwareName: "MuxPlayerSwiftAVPlayerLayer",
            expectedPlayerSoftwareVersion: SemanticVersion.versionString
        )

        try validate(
            context: testPlayerObservationContext,
            expectedPlayerName: "test-player-name"
        )

        try validate(
            context: testPlayerObservationContext,
            expectedEnvironmentKey: "xyz321"
        )

        try validate(
            context: testPlayerObservationContext,
            expectedViewDRMType: "fairplay"
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
