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

//    lazy var playerViewController = AVPlayerViewController(
//        playbackID: playbackID
//    )
    let videoIdx = 0
    lazy var playerViewController = AVPlayerViewController(
        playbackID: DRMExample.DRM_EXAMPLES[videoIdx].playbackID,
        playbackOptions: PlaybackOptions(
            playbackToken: DRMExample.DRM_EXAMPLES[videoIdx].playbackToken,
            drmToken: DRMExample.DRM_EXAMPLES[videoIdx].drmToken,
            customDomain: "staging.mux.com"
        )
    )

//    var playbackID: String = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

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
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            playerViewController.view.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            playerViewController.view.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            playerViewController.view.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            playerViewController.view.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            playerViewController.view.layoutMarginsGuide.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            playerViewController.view.layoutMarginsGuide.bottomAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        let player = playerViewController.player
        let item = playerViewController.player?.currentItem
        
        playerViewController.player?.currentItem?.observe(\AVPlayerItem.status, options: [.new]) { object, change in
            print("Player Item Status: \(change.newValue)")
            if case .failed = change.newValue {
                print("!!AVPlayer Error!!")
                let error = object.error
                print(error!.localizedDescription)
            }
        }
        
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
