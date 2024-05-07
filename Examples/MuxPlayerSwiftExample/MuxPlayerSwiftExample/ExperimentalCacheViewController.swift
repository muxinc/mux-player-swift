//
//  ExperimentalCacheViewController.swift
//  MuxPlayerSwiftExample
//

import AVKit
import UIKit

import MuxPlayerSwift
import MUXSDKStats

class ExperimentalCacheViewController: UIViewController {

//    var playbackID: String = "a4nOgmxGWg6gULfcBbAa00gXyfcwPnAFldF8RdsNyk8M" // Playback ID w/TS
//    var playbackID: String = "u1v00DuRr01bjKb01E8TEFgBfDDggNLWYSk" // Playback ID w/CMAF
    var playbackID: String = "00OgglAoBFLF02Q00ylnxUcU1Zj1uRaRGsAAZJQqfYIYNE" // Playback ID w/TS
//    var playbackID: String = "u1v00DuRr01bjKb01E8TEFgBfDDggNLWYSk"  Playback ID w/CMAF

    lazy var topPlayerViewController = AVPlayerViewController(
        playbackID: playbackID,
        playbackOptions: PlaybackOptions.init(
            renditionOrder: .descending,
            enableSmartCache: true
        ),
        monitoringOptions: monitoringOptions(
            playerName: "ExperimentalCache-TopPlayer",
            experimentName: "CacheEnabled-AllRenditions-DefaultOrder"
        )
    )

    lazy var bottomPlayerViewController = AVPlayerViewController(
        playbackID: playbackID,
        playbackOptions: PlaybackOptions(),
        monitoringOptions: monitoringOptions(
            playerName: "ExperimentalCache-BottomPlayer",
            experimentName: "CacheDisabled-AllRenditions"
        )
    )

    func monitoringOptions(
        playerName: String,
        experimentName: String
    ) -> MonitoringOptions {

        let customerVideoData = MUXSDKCustomerVideoData()
        customerVideoData.videoVariantName = experimentName

        let customerPlayerData = MUXSDKCustomerPlayerData()
        customerPlayerData.environmentKey = "qr9665qr78dac0hqld9bjofps"
        customerPlayerData.experimentName = experimentName

        let customerData = MUXSDKCustomerData()
        customerData.customerVideoData = customerVideoData
        customerData.customerPlayerData = customerPlayerData

        return MonitoringOptions(
            customerData: customerData,
            playerName: playerName
        )
    }

    var experimentName: String = "CacheEnabled-AllRenditions"

    var minimumResolutionTier: MinResolutionTier = .default {
        didSet {
            topPlayerViewController.player?.pause()
            bottomPlayerViewController.player?.pause()

            hidePlayerViewController(
                playerViewController: topPlayerViewController
            )
            self.topPlayerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                ),
                monitoringOptions: monitoringOptions(
                    playerName: "ExperimentalCache-TopPlayer",
                    experimentName: "CacheEnabled-AllRenditions"
                )
            )
            displayPlayerViewController(
                playerViewController: topPlayerViewController,
                layoutConstraints: [
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
                ]
            )

            hidePlayerViewController(
                playerViewController: bottomPlayerViewController
            )
            self.bottomPlayerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                ),
                monitoringOptions: monitoringOptions(
                    playerName: "ExperimentalCache-Bottom",
                    experimentName: "CacheEnabled-AllRenditions"
                )
            )
            displayPlayerViewController(
                playerViewController: bottomPlayerViewController,
                layoutConstraints: [
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
                ]
            )

            topPlayerViewController.player?.play()
            bottomPlayerViewController.player?.play()
        }
    }

    var maximumResolutionTier: MaxResolutionTier = .default {
        didSet {
            topPlayerViewController.player?.pause()
            bottomPlayerViewController.player?.pause()

            hidePlayerViewController(
                playerViewController: topPlayerViewController
            )
            self.topPlayerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                ),
                monitoringOptions: monitoringOptions(
                    playerName: "ExperimentalCache-TopPlayer",
                    experimentName: "CacheEnabled-AllRenditions"
                )
            )
            displayPlayerViewController(
                playerViewController: topPlayerViewController,
                layoutConstraints: [
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
                ]
            )

            hidePlayerViewController(
                playerViewController: bottomPlayerViewController
            )
            self.bottomPlayerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                ),
                monitoringOptions: monitoringOptions(
                    playerName: "ExperimentalCache-BottomPlayer",
                    experimentName: "CacheEnabled-AllRenditions"
                )
            )
            displayPlayerViewController(
                playerViewController: bottomPlayerViewController,
                layoutConstraints: [
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
                ]
            )

            topPlayerViewController.player?.play()
            bottomPlayerViewController.player?.play()
        }
    }

    var renditionOrder: RenditionOrder = .default {
        didSet {
            topPlayerViewController.player?.pause()
            bottomPlayerViewController.player?.pause()

            hidePlayerViewController(
                playerViewController: topPlayerViewController
            )
            self.topPlayerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                )
            )
            displayPlayerViewController(
                playerViewController: topPlayerViewController,
                layoutConstraints: [
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
                ]
            )

            hidePlayerViewController(
                playerViewController: bottomPlayerViewController
            )
            self.bottomPlayerViewController = AVPlayerViewController(
                playbackID: self.playbackID,
                playbackOptions: PlaybackOptions(
                    maximumResolutionTier: self.maximumResolutionTier,
                    minimumResolutionTier: self.minimumResolutionTier,
                    renditionOrder: self.renditionOrder
                )
            )
            displayPlayerViewController(
                playerViewController: bottomPlayerViewController,
                layoutConstraints: [
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
                ]
            )

            topPlayerViewController.player?.play()
            bottomPlayerViewController.player?.play()
        }
    }

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

        displayPlayerViewController(
            playerViewController: topPlayerViewController,
            layoutConstraints: [
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
            ]
        )

        displayPlayerViewController(
            playerViewController: bottomPlayerViewController,
            layoutConstraints: [
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
            ]
        )

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

        let experimentsMenu = UIMenu(
            title: "Experiment Names",
            children: [
                UIAction(
                    title: "CacheEnabled-AllRenditions",
                    handler: { _ in
                        self.experimentName = "CacheEnabled-AllRenditions"
                    }
                ),
                UIAction(
                    title: "CacheDisabled-AllRenditions",
                    handler: { _ in
                        self.experimentName = "CacheDisabled-AllRenditions"
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

    func displayPlayerViewController(
        playerViewController: AVPlayerViewController,
        layoutConstraints: [NSLayoutConstraint]
    ) {
        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)

        playerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(layoutConstraints)
    }

    func hidePlayerViewController(
        playerViewController: AVPlayerViewController
    ) {
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }

    func recreatePlayerInstances() {
        self.topPlayerViewController = AVPlayerViewController(
            playbackID: playbackID,
            monitoringOptions: monitoringOptions(
                playerName: "ExperimentalCache-TopPlayer",
                experimentName: "CacheEnabled-AllRenditions"
            )
        )

        displayPlayerViewController(
            playerViewController: topPlayerViewController,
            layoutConstraints: [
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
            ]
        )

        self.bottomPlayerViewController = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(),
            monitoringOptions: monitoringOptions(
                playerName: "ExperimentalCache-BottomPlayer",
                experimentName: "CacheEnabled-AllRenditions"
            )
        )

        displayPlayerViewController(
            playerViewController: bottomPlayerViewController,
            layoutConstraints: [
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
            ]
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

        print("ABR \(#function) URI: \(String(describing: lastEvent.uri))")

        print("Current Indicated Bitrate: \(lastEvent.indicatedBitrate)")

        print("Current Observed Bitrate: \(lastEvent.observedBitrate)")

        print("Current Switch Bitrate: \(lastEvent.switchBitrate)")

        print("Observed Bitrate Standard Deviation: \(lastEvent.observedBitrateStandardDeviation)")

        print("Requested Rendition URI: \(String(describing: lastEvent.uri))")
    }
}
