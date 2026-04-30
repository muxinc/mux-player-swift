//
//  MuxPlayerSwiftExampleApp.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import SwiftUI
import MuxPlayerSwift

@main
struct MuxPlayerSwiftExampleApp: App {
    init() {
        MuxOfflineAccessManager.shared.resumePendingDownloadTasks()
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            RootContentView()
        }
    }

    private func configureAudioSession() {
        Task {
            let audioSession = AVAudioSession.sharedInstance()

            var mediaServicesResetNotifications = NotificationCenter.default
                .notifications(
                    named: AVAudioSession.mediaServicesWereResetNotification,
                    object: audioSession
                )
                .compactMap { _ in }
                .makeAsyncIterator()

            repeat {
                do {
                    try audioSession.setCategory(.playback)
                } catch {
                    print("Setting category to AVAudioSessionCategoryPlayback failed.")
                }

                await mediaServicesResetNotifications.next()
            } while true
        }
    }
}
