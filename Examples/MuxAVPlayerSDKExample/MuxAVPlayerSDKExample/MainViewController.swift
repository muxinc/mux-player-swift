//
//  MainViewController.swift
//  MuxAVPlayerSDKExample
//

import AVFoundation
import AVKit
import SwiftUI
import UIKit

import MuxAVPlayerSDK

struct MainView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let mainViewController = MainViewController()
        return mainViewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {

    }
}

class MainViewController: UIViewController {

    lazy var playerViewController = AVPlayerViewController(
        playbackID: playbackID
    )

    var playbackID: String = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)

        playerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = true
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        playerViewController.player?.pause()
        playerViewController.stopMonitoring()
        super.viewWillDisappear(animated)
    }

}
