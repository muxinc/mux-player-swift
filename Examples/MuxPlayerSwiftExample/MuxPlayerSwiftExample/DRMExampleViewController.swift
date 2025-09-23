//
//  DRMExampleViewController.swift
//  MuxPlayerSwiftExample
//

import AVKit
import UIKit

import MuxPlayerSwift

class DRMExampleViewController: UIViewController {

    // MARK: Player View Controller

    private var observations: [NSKeyValueObservation] = []

    lazy var playerViewController = {
        let viewController = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )

        let errorObservation = viewController.observe(\.player?.error, options: .initial) { [weak self] viewController, _ in
            if let error = viewController.player?.error as? AVError,
               error.code == .mediaServicesWereReset {
                self?.handleMediaServicesReset()
            }
        }
        observations.append(errorObservation)

        return viewController
    }()

    func handleMediaServicesReset() {
        // Recreate the current item
        let playerItem = AVPlayerItem(
            playbackID: playbackID,
            playbackOptions: playbackOptions)

        // Restore any desired state on the item
        if let currentTime = playerViewController.player?.currentItem?.currentTime() {
            playerItem.seek(to: currentTime, completionHandler: nil)
        }

        // Recreate the player
        let player = AVPlayer(playerItem: playerItem)

        // Restore any desired state on the player

        // With the new changes on the MUXSDKStats branch, monitoring will resume automatically:
        playerViewController.player = player
    }

    // MARK: Mux Data Monitoring Parameters

    var playerName: String = "MuxPlayerSwift-DRMExample"

    var environmentKey: String? {
        ProcessInfo.processInfo.environmentKey
    }

    // MARK: Mux Video Playback Parameters

    var playbackID: String {
        ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    // TODO: Display error alert if ProcessInfo returns nil
    var playbackToken: String {
        ProcessInfo.processInfo.playbackToken ?? ""
    }

    // TODO: Display error alert if ProcessInfo returns nil
    var drmToken: String {
        ProcessInfo.processInfo.drmToken ?? ""
    }

    // TODO: Display error alert if ProcessInfo returns nil
    var customDomain: String? {
        ProcessInfo.processInfo.customDomain ?? nil
    }

    lazy var playbackOptions = PlaybackOptions(
        playbackToken: playbackToken,
        drmToken: drmToken,
        customDomain: customDomain
    )

    // MARK: Status Bar Appearance

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        playerViewController.delegate = self
        playerViewController.allowsPictureInPicturePlayback = true
        playerViewController.canStartPictureInPictureAutomaticallyFromInline = true

        displayPlayerViewController()
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
            playerViewController.view.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            playerViewController.view.bottomAnchor
                .constraint(equalTo: view.bottomAnchor),
        ])
    }

    func hidePlayerViewController() {
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }

    deinit {
        playerViewController.stopMonitoring()
    }
}

extension DRMExampleViewController: AVPlayerViewControllerDelegate{
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}
