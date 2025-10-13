//
//  AppDelegate.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Task {
            let audioSession = AVAudioSession.sharedInstance()

            var mediaServicesResetNotifications = NotificationCenter.default
                .notifications(named: AVAudioSession.mediaServicesWereResetNotification,
                               object: audioSession)
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

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

