//
//  DRMPlayer.swift
//  MuxPlayerSwiftExample
//

import AVKit
import SwiftUI
import MuxPlayerSwift

struct DRMPlayer: View {
    var body: some View {
        // Play the protected stream when credentials are set; otherwise show
        // setup instructions instead of failing silently. See DRMPlaybackCredentials.
        if let credentials = DRMPlaybackCredentials.resolved {
            DRMPlayerRepresentable(
                playbackID: credentials.playbackID,
                playbackToken: credentials.playbackToken,
                drmToken: credentials.drmToken,
                customDomain: credentials.customDomain
            )
            .ignoresSafeArea()
            .background(.black)
            .accessibilityIdentifier("DRMPlayerView")
        } else {
            DRMSetupInstructionsView()
                .accessibilityIdentifier("DRMSetupInstructionsView")
        }
    }
}

#Preview {
    DRMPlayer()
}

// MARK: - Playback Configuration

/// Credentials for a Mux DRM (FairPlay) stream: a DRM-enabled `playbackID`, a
/// `playbackToken` (authorizes playback) and a `drmToken` (authorizes the
/// FairPlay license), both signed JWTs.
///
/// Empty by default — paste your own values below (don't commit real tokens), or
/// set the PLAYBACK_ID / PLAYBACK_TOKEN / DRM_TOKEN scheme env vars, which win.
enum DRMPlaybackCredentials {

    // 👇 Paste your DRM-enabled playback ID and signed tokens here.
    static let playbackID = ""
    static let playbackToken = ""
    static let drmToken = ""

    /// Env vars take precedence over the constants. Returns `nil` if any field
    /// is empty, so the screen can show setup instructions instead of failing.
    static var resolved: Resolved? {
        let id = ProcessInfo.processInfo.playbackID ?? playbackID
        let playback = ProcessInfo.processInfo.playbackToken ?? playbackToken
        let drm = ProcessInfo.processInfo.drmToken ?? drmToken

        guard !id.isEmpty, !playback.isEmpty, !drm.isEmpty else {
            return nil
        }

        return Resolved(
            playbackID: id,
            playbackToken: playback,
            drmToken: drm,
            customDomain: ProcessInfo.processInfo.customDomain
        )
    }

    struct Resolved {
        let playbackID: String
        let playbackToken: String
        let drmToken: String
        let customDomain: String?
    }
}

// MARK: - Setup Instructions

/// Shown when no DRM credentials are configured: explains what the screen does
/// and how to enable it, instead of a blank screen or silent failure.
private struct DRMSetupInstructionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("DRM Playback")
                    .font(.title2.bold())

                Text("This example plays a FairPlay (DRM) protected Mux stream. Nothing is playing because no DRM credentials are configured.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("To try it:")
                        .font(.headline)
                    Label("Use a DRM-enabled Mux playback ID.", systemImage: "1.circle")
                    Label("Create a playback token and a DRM token, both signed with your Mux signing key.", systemImage: "2.circle")
                    Label("Paste all three into the constants at the top of DRMPlayer.swift — or set the PLAYBACK_ID / PLAYBACK_TOKEN / DRM_TOKEN environment variables in the Xcode scheme.", systemImage: "3.circle")
                }

                Text("Once all three are set, this screen plays the protected stream automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - UIKit Bridge

private struct DRMPlayerRepresentable: UIViewControllerRepresentable {
    let playbackID: String
    let playbackToken: String
    let drmToken: String
    let customDomain: String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController(
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(
                playbackToken: playbackToken,
                drmToken: drmToken,
                customDomain: customDomain
            )
        )
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.player?.play()
        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: AVPlayerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.player?.pause()
        uiViewController.stopMonitoring()
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(true)
        }
    }
}
