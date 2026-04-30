//
//  SinglePlayer.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import SwiftUI
import MuxPlayerSwift

struct SinglePlayer: View {
    @State private var maximumResolutionTier: MaxResolutionTier = .default
    @State private var minimumResolutionTier: MinResolutionTier = .default
    @State private var renditionOrder: RenditionOrder = .default
    @State private var clipStartTime: Double?
    @State private var clipEndTime: Double?
    @State private var isPlayerPresented = false

    var body: some View {
        Form {
            Section {
                Picker("Maximum", selection: $maximumResolutionTier) {
                    Text("Default").tag(MaxResolutionTier.default)
                    Text("Up to 720p").tag(MaxResolutionTier.upTo720p)
                    Text("Up to 1080p").tag(MaxResolutionTier.upTo1080p)
                    Text("Up to 1440p").tag(MaxResolutionTier.upTo1440p)
                    Text("Up to 2160p").tag(MaxResolutionTier.upTo2160p)
                }

                Picker("Minimum", selection: $minimumResolutionTier) {
                    Text("Default").tag(MinResolutionTier.default)
                    Text("At least 480p").tag(MinResolutionTier.atLeast480p)
                    Text("At least 540p").tag(MinResolutionTier.atLeast540p)
                    Text("At least 720p").tag(MinResolutionTier.atLeast720p)
                    Text("At least 1080p").tag(MinResolutionTier.atLeast1080p)
                    Text("At least 1440p").tag(MinResolutionTier.atLeast1440p)
                    Text("At least 2160p").tag(MinResolutionTier.atLeast2160p)
                }
            } header: {
                Text("Resolution")
            } footer: {
                if let resolutionError {
                    Text(resolutionError)
                        .foregroundStyle(.red)
                }
            }

            Section("Rendition Order") {
                Picker("Rendition Order", selection: $renditionOrder) {
                    Text("Default").tag(RenditionOrder.default)
                    Text("Descending").tag(RenditionOrder.descending)
                }
            }

            Section {
                LabeledContent("Start (seconds)") {
                    TextField(
                        "Optional",
                        value: $clipStartTime,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("ClipStartTimeField")
                }

                LabeledContent("End (seconds)") {
                    TextField(
                        "Optional",
                        value: $clipEndTime,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("ClipEndTimeField")
                }
            } header: {
                Text("Clip Range")
            } footer: {
                if let clipRangeError {
                    Text(clipRangeError)
                        .foregroundStyle(.red)
                }
            }
        }
        .accessibilityIdentifier("SinglePlayerView")
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Play Video") {
                    isPlayerPresented = true
                }
                .disabled(hasValidationError)
            }
        }
        .fullScreenCover(isPresented: $isPlayerPresented) {
            SinglePlayerRepresentable(
                playbackID: playbackID,
                playbackOptions: playbackOptions,
                monitoringOptions: monitoringOptions
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        SinglePlayer()
    }
}

// MARK: - Playback Configuration

extension SinglePlayer {
    private var playbackID: String {
        ProcessInfo.processInfo.playbackID
            ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    private var environmentKey: String? {
        ProcessInfo.processInfo.environmentKey
    }

    private var monitoringOptions: MonitoringOptions {
        if let environmentKey {
            MonitoringOptions(
                environmentKey: environmentKey,
                playerName: "MuxPlayerSwift-SinglePlayerExample"
            )
        } else {
            MonitoringOptions(
                playbackID: playbackID
            )
        }
    }

    private var playbackOptions: PlaybackOptions {
        PlaybackOptions(
            maximumResolutionTier: maximumResolutionTier,
            minimumResolutionTier: minimumResolutionTier,
            renditionOrder: renditionOrder,
            clipping: InstantClipping(
                assetStartTimeInSeconds: clipStartTime ?? .nan,
                assetEndTimeInSeconds: clipEndTime ?? .nan
            )
        )
    }
}

// MARK: - Validation

extension SinglePlayer {
    private var resolutionError: String? {
        guard let maxPixels = maximumResolutionTier.pixels,
              let minPixels = minimumResolutionTier.pixels,
              minPixels > maxPixels else {
            return nil
        }
        return "Minimum resolution exceeds maximum resolution."
    }

    private var clipRangeError: String? {
        guard let start = clipStartTime,
              let end = clipEndTime,
              start >= end else {
            return nil
        }
        return "Start time must be less than end time."
    }

    private var hasValidationError: Bool {
        resolutionError != nil || clipRangeError != nil
    }
}

// MARK: - Resolution Tier Helpers

private extension MaxResolutionTier {
    var pixels: Int? {
        switch self {
        case .default: nil
        case .upTo720p: 720
        case .upTo1080p: 1080
        case .upTo1440p: 1440
        case .upTo2160p: 2160
        }
    }
}

private extension MinResolutionTier {
    var pixels: Int? {
        switch self {
        case .default: nil
        case .atLeast480p: 480
        case .atLeast540p: 540
        case .atLeast720p: 720
        case .atLeast1080p: 1080
        case .atLeast1440p: 1440
        case .atLeast2160p: 2160
        }
    }
}

// MARK: - UIKit Bridge

private struct SinglePlayerRepresentable: UIViewControllerRepresentable {
    let playbackID: String
    let playbackOptions: PlaybackOptions
    let monitoringOptions: MonitoringOptions

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            monitoringOptions: monitoringOptions
        )
        controller.player?.play()
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: AVPlayerViewController,
        coordinator: ()
    ) {
        uiViewController.player?.pause()
        uiViewController.stopMonitoring()
    }
}
