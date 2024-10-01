//
//  SinglePlayerExampleController.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import SwiftUI
import UIKit

import MuxPlayerSwift

// Single player example
class SinglePlayerExampleController: UIViewController {

    // MARK: Player View Controller

    lazy var playerViewController = AVPlayerViewController(
        playbackID: playbackID
    )

    // MARK: Mux Data Monitoring Parameters

    var playerName: String = "MuxPlayerSwift-SinglePlayerExample"

    var environmentKey: String? {
        ProcessInfo.processInfo.environmentKey
    }

    var monitoringOptions: MonitoringOptions {
        if let environmentKey {
            MonitoringOptions(
                environmentKey: environmentKey,
                playerName: playerName
            )
        } else {
            MonitoringOptions(
                playbackID: playbackID
            )
        }
    }

    // MARK: Mux Video Playback Parameters

    var playbackID: String {
        ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    var minimumResolutionTier: MinResolutionTier = .default {
        didSet {
            playerViewController.prepare(
                playbackID: playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: maximumResolutionTier,
                    minimumResolutionTier: minimumResolutionTier,
                    renditionOrder: renditionOrder
                ),
                monitoringOptions: monitoringOptions
            )
        }
    }

    var maximumResolutionTier: MaxResolutionTier = .default {
        didSet {
            playerViewController.prepare(
                playbackID: playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: maximumResolutionTier,
                    minimumResolutionTier: minimumResolutionTier,
                    renditionOrder: renditionOrder
                ),
                monitoringOptions: monitoringOptions
            )
        }
    }

    var renditionOrder: RenditionOrder = .default {
        didSet {
            playerViewController.prepare(
                playbackID: playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: maximumResolutionTier,
                    minimumResolutionTier: minimumResolutionTier,
                    renditionOrder: renditionOrder
                ),
                monitoringOptions: monitoringOptions
            )
        }
    }

    // MARK: Status Bar Appearance

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        view.accessibilityLabel = "A single player example that uses AVPlayerViewController"
        view.accessibilityIdentifier = "SinglePlayerView"

        let maximumResolutionsMenu = UIMenu(
            title: "Set Maximum Resolution",
            children: [
                UIAction(
                    title: "Default",
                    handler: { _ in
                        self.maximumResolutionTier = .default
                    }
                ),
                UIAction(
                    title: "Up to 720p",
                    handler: { _ in
                        self.maximumResolutionTier = .upTo720p
                    }
                ),
                UIAction(
                    title: "Up to 1080p",
                    handler: { _ in
                        self.maximumResolutionTier = .upTo1080p
                    }
                ),
                UIAction(
                    title: "Up to 1440p",
                    handler: { _ in
                        self.maximumResolutionTier = .upTo1440p
                    }
                ),
                UIAction(
                    title: "Up to 2160p",
                    handler: { _ in
                        self.maximumResolutionTier = .upTo2160p
                    }
                )
            ]
        )

        let minimumResolutionsMenu = UIMenu(
            title: "Set Minimum Resolution",
            children: [
                UIAction(
                    title: "Default",
                    handler: { _ in
                        self.minimumResolutionTier = .default
                    }
                ),
                UIAction(
                    title: "At least 480p",
                    handler: { _ in
                        self.minimumResolutionTier = .atLeast480p
                    }
                ),
                UIAction(
                    title: "At least 540p",
                    handler: { _ in
                        self.minimumResolutionTier = .atLeast540p
                    }
                ),
                UIAction(
                    title: "At least 720p",
                    handler: { _ in
                        self.minimumResolutionTier = .atLeast720p
                    }
                ),
                UIAction(
                    title: "At least 1080p",
                    handler: { _ in
                        self.minimumResolutionTier = .atLeast1080p
                    }
                ),
                UIAction(
                    title: "At least 1440p",
                    handler: { _ in
                        self.minimumResolutionTier = .atLeast1440p
                    }
                ),
                UIAction(
                    title: "At least 2160p",
                    handler: { _ in
                        self.minimumResolutionTier = .atLeast2160p
                    }
                ),
            ]
        )

        let renditionOrderMenu = UIMenu(
            title: "Set Rendition Order",
            children: [
                UIAction(
                    title: "Default",
                    handler: { _ in
                        self.renditionOrder = .default
                    }
                ),
                UIAction(
                    title: "Descending",
                    handler: { _ in
                        self.renditionOrder = .descending
                    }
                ),
            ]
        )

        let optionsMenu = UIMenu(
            children: [
                maximumResolutionsMenu,
                minimumResolutionsMenu,
                renditionOrderMenu
            ]
        )


        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Adjust SDK Options",
            menu: optionsMenu
        )

        displayPlayerViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.playerViewController.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        playerViewController.player?.pause()
        playerViewController.stopMonitoring()
        super.viewWillDisappear(animated)
    }

    // MARK: Player Lifecycle

    func displayPlayerViewController() {
        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
        playerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            playerViewController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            playerViewController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            playerViewController.view.layoutMarginsGuide.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            playerViewController.view.layoutMarginsGuide.bottomAnchor
                .constraint(equalTo: view.bottomAnchor),
        ])
    }

    func hidePlayerViewController() {
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }

}
