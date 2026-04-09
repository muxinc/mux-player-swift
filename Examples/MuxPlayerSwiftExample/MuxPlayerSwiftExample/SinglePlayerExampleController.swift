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
            preparePlayerViewController()
        }
    }

    var maximumResolutionTier: MaxResolutionTier = .default {
        didSet {
            preparePlayerViewController()
        }
    }

    var renditionOrder: RenditionOrder = .default {
        didSet {
            preparePlayerViewController()
        }
    }

    var assetStartTimeInSeconds: Double = .nan {
        didSet {
            preparePlayerViewController()
        }
    }


    var assetEndTimeInSeconds: Double = .nan {
        didSet {
            preparePlayerViewController()
        }
    }

    var programStartTimeInSeconds: Double = .nan {
        didSet {
            preparePlayerViewController()
        }
    }

    var programEndTimeInSeconds: Double = .nan {
        didSet {
            preparePlayerViewController()
        }
    }

    func preparePlayerViewController() {
        playerViewController.prepare(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(
                maximumResolutionTier: maximumResolutionTier,
                minimumResolutionTier: minimumResolutionTier,
                renditionOrder: renditionOrder,
                clipping: InstantClipping(
                    assetStartTimeInSeconds: assetStartTimeInSeconds,
                    assetEndTimeInSeconds: assetEndTimeInSeconds
                )
            ),
            monitoringOptions: monitoringOptions
        )
    }

    // MARK: Status Bar Appearance

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityLabel = "A single player example that uses AVPlayerViewController"
        view.accessibilityIdentifier = "SinglePlayerView"

        let maximumResolutionSelectionControl = UISegmentedControl()

        let defaultMaxResolutionAction = UIAction(
            title: "Default"
        ) { _ in
            self.maximumResolutionTier = .default
        }

        maximumResolutionSelectionControl.insertSegment(
            action: defaultMaxResolutionAction,
            at: 0,
            animated: false
        )

        let upTo720pAction = UIAction(
            title: "Up to 720p"
        ) { _ in
            self.maximumResolutionTier = .upTo720p
        }

        maximumResolutionSelectionControl.insertSegment(
            action: upTo720pAction,
            at: 1,
            animated: false
        )

        let upTo1080pAction = UIAction(
            title: "Up to 1080p"
        ) { _ in
            self.maximumResolutionTier = .upTo1080p
        }

        maximumResolutionSelectionControl.insertSegment(
            action: upTo1080pAction,
            at: 2,
            animated: false
        )

        let upTo1440pAction = UIAction(
            title: "Up to 1440p"
        ) { _ in
            self.maximumResolutionTier = .upTo1440p
        }

        maximumResolutionSelectionControl.insertSegment(
            action: upTo1440pAction,
            at: 3,
            animated: false
        )

        let upTo2160pAction = UIAction(
            title: "Up to 2160p"
        ) { _ in
            self.maximumResolutionTier = .upTo2160p
        }

        maximumResolutionSelectionControl.insertSegment(
            action: upTo2160pAction,
            at: 4,
            animated: false
        )

        let minimumResolutionSelectionControl = UISegmentedControl()

        let defaultMinimumResolutionAction = UIAction(
            title: "Default",
            handler: { _ in
                self.minimumResolutionTier = .default
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: defaultMinimumResolutionAction,
            at: 0,
            animated: false
        )

        let atLeast480pAction = UIAction(
            title: "At least 480p",
            handler: { _ in
                self.minimumResolutionTier = .atLeast480p
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: atLeast480pAction,
            at: 1,
            animated: false
        )

        let atLeast540pAction = UIAction(
            title: "At least 540p",
            handler: { _ in
                self.minimumResolutionTier = .atLeast540p
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: atLeast540pAction,
            at: 2,
            animated: false
        )

        let atLeast720pAction = UIAction(
            title: "At least 720p",
            handler: { _ in
                self.minimumResolutionTier = .atLeast720p
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: atLeast720pAction,
            at: 3,
            animated: false
        )

        let atLeast1080pAction = UIAction(
            title: "At least 1080p",
            handler: { _ in
                self.minimumResolutionTier = .atLeast1080p
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: atLeast1080pAction,
            at: 4,
            animated: false
        )

        let atLeast1440pAction = UIAction(
            title: "At least 1440p",
            handler: { _ in
                self.minimumResolutionTier = .atLeast1440p
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: atLeast1440pAction,
            at: 5,
            animated: false
        )

        let atLeast2160pAction = UIAction(
            title: "At least 2160p",
            handler: { _ in
                self.minimumResolutionTier = .atLeast2160p
            }
        )

        minimumResolutionSelectionControl.insertSegment(
            action: atLeast2160pAction,
            at: 6,
            animated: false
        )

        let renditionOrderSelectionControl = UISegmentedControl()

        let defaultRenditionOrderAction = UIAction(
            title: "Default",
            handler: { _ in
                self.renditionOrder = .default
            }
        )

        renditionOrderSelectionControl.insertSegment(
            action: defaultRenditionOrderAction,
            at: 0,
            animated: false
        )

        let descendingRenditionOrderAction = UIAction(
            title: "Descending",
            handler: { _ in
                self.renditionOrder = .descending
            }
        )

        renditionOrderSelectionControl.insertSegment(
            action: descendingRenditionOrderAction,
            at: 1,
            animated: false
        )

        let maximumResolutionLabel = UILabel()
        maximumResolutionLabel.textAlignment = .center
        maximumResolutionLabel.text = "Maximum Resolution"

        let minimumResolutionLabel = UILabel()
        minimumResolutionLabel.textAlignment = .center
        minimumResolutionLabel.text = "Minimum Resolution"

        let renditionOrderLabel = UILabel()
        renditionOrderLabel.textAlignment = .center
        renditionOrderLabel.text = "Rendition Order"

        maximumResolutionSelectionControl.selectedSegmentIndex = 0

        minimumResolutionSelectionControl.selectedSegmentIndex = 0

        renditionOrderSelectionControl.selectedSegmentIndex = 0

        let assetStartTimeTextField = UITextField(
            frame: .zero,
            primaryAction: UIAction(
                handler: { action in
                    if let text = (action.sender as? UITextField)?.text {
                        self.assetStartTimeInSeconds = (
                            try? Double(
                                text,
                                format: .number
                            )
                        ) ?? .nan
                    }
                }
            )
        )
        assetStartTimeTextField.keyboardType = .decimalPad
        assetStartTimeTextField.placeholder = "Clip starting time if desired"

        let assetEndTimeTextField = UITextField(
            frame: .zero,
            primaryAction: UIAction(
                handler: { action in
                    if let text = (action.sender as? UITextField)?.text {
                        self.assetEndTimeInSeconds = (
                            try? Double(
                                text,
                                format: .number
                            )
                        ) ?? .nan
                    }
                }
            )
        )
        assetEndTimeTextField.keyboardType = .decimalPad
        assetEndTimeTextField.placeholder = "Clip ending time if desired"

        let programStartTimeTextField = UITextField(
            frame: .zero,
            primaryAction: UIAction(
                handler: { action in
                    if let text = (action.sender as? UITextField)?.text {
                        self.programStartTimeInSeconds = (
                            try? Double(
                                text,
                                format: .number
                            )
                        ) ?? .nan
                    }
                }
            )
        )

        programStartTimeTextField.keyboardType = .decimalPad
        programStartTimeTextField.placeholder = "Clip ending program date and time if desired"

        let programEndTimeTextField = UITextField(
            frame: .zero,
            primaryAction: UIAction(
                handler: { action in
                    if let text = (action.sender as? UITextField)?.text {
                        self.programEndTimeInSeconds = (
                            try? Double(
                                text,
                                format: .number
                            )
                        ) ?? .nan
                    }
                }
            )
        )

        programEndTimeTextField.keyboardType = .decimalPad
        programEndTimeTextField.placeholder = "Clip ending program date and time if desired"

        let stackView = UIStackView(
            arrangedSubviews: [
                maximumResolutionLabel,
                maximumResolutionSelectionControl,
                minimumResolutionLabel,
                minimumResolutionSelectionControl,
                renditionOrderLabel,
                renditionOrderSelectionControl,
                assetStartTimeTextField,
                assetEndTimeTextField
            ]
        )
        stackView.axis = .vertical
        stackView.spacing = 25.0

        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        view.addConstraints([
            stackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 30.0
            ),
            stackView.widthAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.widthAnchor,
                multiplier: 0.9
            ),
            stackView.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor
            )
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Play Video",
            primaryAction: UIAction(
                handler: { _ in
                    self.displayPlayerViewController()
                }
            )
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        playerViewController.player?.pause()
        super.viewDidDisappear(animated)
    }

    // MARK: Player Lifecycle

    func displayPlayerViewController() {
        present(
            playerViewController,
            animated: true
        ) {
            self.playerViewController.player?.play()
        }
    }

    func hidePlayerViewController() {
        dismiss(
            animated: true
        )
    }

    deinit {
        playerViewController.stopMonitoring()
    }
}
