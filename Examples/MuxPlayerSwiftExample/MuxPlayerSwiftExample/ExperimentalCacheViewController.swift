//
//  ExperimentalCacheViewController.swift
//  MuxPlayerSwiftExample
//

import AVKit
import UIKit

import MuxPlayerSwift

class ExperimentalCacheViewController: UIViewController {

    var playbackID: String = "a4nOgmxGWg6gULfcBbAa00gXyfcwPnAFldF8RdsNyk8M"

    lazy var topPlayerViewController = AVPlayerViewController(
        playbackID: playbackID,
        playbackOptions: PlaybackOptions.init(
            maximumResolutionTier: .upTo720p,
            minimumResolutionTier: .atLeast720p
        )
    )

    lazy var bottomPlayerViewController = AVPlayerViewController(
        playbackID: playbackID,
        playbackOptions: PlaybackOptions.init(
            maximumResolutionTier: .upTo720p,
            minimumResolutionTier: .atLeast720p
        )
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        topPlayerViewController.willMove(toParent: self)
        addChild(topPlayerViewController)
        view.addSubview(topPlayerViewController.view)
        topPlayerViewController.didMove(toParent: self)

        topPlayerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            topPlayerViewController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            topPlayerViewController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            topPlayerViewController.view.layoutMarginsGuide.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            topPlayerViewController.view.layoutMarginsGuide.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: 0.5
            ),
        ])

        bottomPlayerViewController.willMove(toParent: self)
        addChild(bottomPlayerViewController)
        view.addSubview(bottomPlayerViewController.view)
        bottomPlayerViewController.didMove(toParent: self)

        bottomPlayerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            bottomPlayerViewController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            bottomPlayerViewController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            bottomPlayerViewController.view.layoutMarginsGuide.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            bottomPlayerViewController.view.layoutMarginsGuide.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: 0.5
            ),
        ])

        let recreatePlayersNavigationBarButtonItem = UIBarButtonItem(
            title: "Recreate Players",
            image: nil,
            primaryAction: UIAction(
                handler: { _ in
                    self.recreatePlayerInstances()
                }
            )
        )

        let configureAlternativePlaybackIDNavigationBarButtonItem = UIBarButtonItem(
            title: "Configure Alternative Playback ID",
            image: nil,
            primaryAction: UIAction(
                handler: { _ in
                    self.configureAlternativePlaybackID()
                }
            )
        )
        navigationController?.navigationItem.rightBarButtonItems = [
            recreatePlayersNavigationBarButtonItem,
            configureAlternativePlaybackIDNavigationBarButtonItem
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startObservingPlayerAccessLog()

//        self.topPlayerViewController.player?.play()

        self.topPlayerViewController.player?.isMuted = true
        self.bottomPlayerViewController.player?.isMuted = true

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 20,
            execute: DispatchWorkItem(
                block: {
//                    self.bottomPlayerViewController.player?.play()
                }
            )
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        topPlayerViewController.player?.pause()
        topPlayerViewController.stopMonitoring()

        bottomPlayerViewController.player?.pause()
        bottomPlayerViewController.stopMonitoring()

        super.viewWillDisappear(animated)
    }

    func recreatePlayerInstances() {
        self.topPlayerViewController = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions.init(
                maximumResolutionTier: .upTo720p,
                minimumResolutionTier: .atLeast720p
            )
        )

        self.bottomPlayerViewController = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions.init(
                maximumResolutionTier: .upTo720p,
                minimumResolutionTier: .atLeast720p
            )
        )
    }

    func configureAlternativePlaybackID() {

    }

    //MARK: Player ABR Observation

    func startObservingPlayerAccessLog() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ExperimentalCacheViewController.handlePlayerAccessLogEntryUpdate),
            name: AVPlayerItem.newAccessLogEntryNotification,
            object: nil
        )
    }

    @objc func handlePlayerAccessLogEntryUpdate(
        _ notification: Notification
    ) {
        guard let playerItem = (notification.object as? AVPlayerItem) else {
            print("\(#function) No player item enclosed with notification")
            return
        }

        print("\(#function) Preferred peak bitrate \(playerItem.preferredPeakBitRate)")

        print("\(#function) Preferred maximum resolution \(playerItem.preferredMaximumResolution)")

        if #available(iOS 15.0, *) {
            print("\(#function) Preferred peak bitrate \(playerItem.preferredPeakBitRateForExpensiveNetworks)")

            print("\(#function) Preferred maximum resolution \(playerItem.preferredMaximumResolutionForExpensiveNetworks)")
        }

        guard let accessLog = playerItem.accessLog() else {
            print("\(#function) No access log enclosed with notification")
            return
        }

        guard let lastEvent = accessLog.events.last else {
            print("\(#function) Access log empty after an update")
            return
        }

        print("\(#function) Current Indicated Bitrate: \(lastEvent.indicatedBitrate)")

        print("\(#function) Current Observed Bitrate: \(lastEvent.observedBitrate)")

        print("\(#function) Current Switch Bitrate: \(lastEvent.switchBitrate)")

        print("\(#function) Observed Bitrate Standard Deviation: \(lastEvent.observedBitrateStandardDeviation)")

        print("ABR \(#function) URI: \(String(describing: lastEvent.uri))")
    }
}
