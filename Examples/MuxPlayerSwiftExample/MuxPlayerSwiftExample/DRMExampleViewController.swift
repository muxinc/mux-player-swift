//
//  DRMExampleViewController.swift
//  MuxPlayerSwiftExample
//

import AVKit
import UIKit

import MuxPlayerSwift

class DRMExampleViewController: UIViewController {

    // MARK: Player View Controller

    lazy var playerViewController = AVPlayerViewController(
        playbackID: playbackID,
        playbackOptions: PlaybackOptions(
            playbackToken: playbackToken,
            drmToken: drmToken,
            customDomain: customDomain
        )
    )

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

    override func viewDidDisappear(_ animated: Bool) {
        playerViewController.stopMonitoring()
        super.viewDidDisappear(animated)
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

}

extension DRMExampleViewController: AVPlayerViewControllerDelegate{
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

import MUXSDKStats // only for the shim below

extension DRMExampleViewController {
    // This should be moved to our AVPlayerViewController initializer, and something similar for AVPlayerLayer
    func shimForPlayerObjectObserving(viewController: AVPlayerViewController) {
        let playerObservation = viewController.observe(\.player) { viewController, _ in
            if let player = viewController.player {
                // should actually be attachPlayer:
                MUXSDKStats.update(viewController, withPlayerName: viewController.muxDataName!)
            } else {
                // should actually be detachPlayer:
                MUXSDKStats.destroyPlayer(viewController.muxDataName!)
            }
        }
        observations.append(playerObservation)
    }
}
