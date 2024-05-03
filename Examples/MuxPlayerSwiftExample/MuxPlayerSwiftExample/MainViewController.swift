//
//  MainViewController.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import SwiftUI
import UIKit

import MuxPlayerSwift

class MainViewController: UIViewController {

    lazy var playerViewController = AVPlayerViewController(
        playbackID: playbackID
    )

    var playbackID: String = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

    var minimumResolutionTier: MinResolutionTier = .default {
        didSet {
            playerViewController.player?.pause()
            hidePlayerViewController()
            self.playerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                )
            )
            displayPlayerViewController()
            playerViewController.player?.play()
        }
    }

    var maximumResolutionTier: MaxResolutionTier = .default {
        didSet {
            playerViewController.player?.pause()
            hidePlayerViewController()
            self.playerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                )
            )
            displayPlayerViewController()
            playerViewController.player?.play()
        }
    }

    var renditionOrder: RenditionOrder = .default {
        didSet {
            playerViewController.player?.pause()
            hidePlayerViewController()
            self.playerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                )
            )
            displayPlayerViewController()
            playerViewController.player?.play()
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let maximumResolutionsMenu = UIMenu(
            title: "Set Maximum Resolution",
            children: [
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
                    title: "Ascending",
                    handler: { _ in
                        self.renditionOrder = .ascending
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

        let playbackModifiersMenu = UIMenu(
            children: [
                maximumResolutionsMenu,
                minimumResolutionsMenu,
                renditionOrderMenu
            ]
        )


        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Adjust Playback Modifiers",
            menu: playbackModifiersMenu
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

    func displayPlayerViewController() {
        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
        playerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            playerViewController.view.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            playerViewController.view.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
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
