//
//  SmartCacheExampleViewController.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import UIKit

import MuxPlayerSwift

class SmartCacheExampleViewController: UIViewController {
    
    // MARK: Player View Controller

    lazy var playerViewController = AVPlayerViewController(
        playbackID: playbackID
    )

    // MARK: Mux Data Monitoring Parameters

    var playerName: String = "MuxPlayerSwift-SmartCacheExample"

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

    var smartCacheEnabled: Bool = true
    var singleRenditionResolutionTier: SingleResolutionTier = .only720p

    // MARK: Status Bar Appearance

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let smartCacheOptionsMenu = UIMenu(
            title: "Smart Cache Options",
            children: [
                UIAction(
                    title: "Enable with 720p renditions",
                    handler: { _ in
                        self.smartCacheEnabled = true
                        self.singleRenditionResolutionTier = .only720p
                    }
                ),
                UIAction(
                    title: "Enable with 1080p renditions",
                    handler: { _ in
                        self.smartCacheEnabled = true
                        self.singleRenditionResolutionTier = .only1080p
                    }
                ),
                UIAction(
                    title: "Enable with 1440p renditions",
                    handler: { _ in
                        self.smartCacheEnabled = true
                        self.singleRenditionResolutionTier = .only1440p
                    }
                ),
                UIAction(
                    title: "Enable with 2160p renditions",
                    handler: { _ in
                        self.smartCacheEnabled = true
                        self.singleRenditionResolutionTier = .only2160p
                    }
                )
            ]
        )

        let optionsMenu = UIMenu(
            children: [
                smartCacheOptionsMenu
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
