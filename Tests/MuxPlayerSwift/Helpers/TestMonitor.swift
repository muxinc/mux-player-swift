//
// TestMonitor.swift
//

import AVKit
import Foundation
import XCTest

@testable import MuxPlayerSwift

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
