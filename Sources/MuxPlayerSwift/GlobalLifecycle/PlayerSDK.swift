//
//  PlayerSDK.swift
//

import Foundation

// internal class to manage dependency injection
class PlayerSDK {

    #if DEBUG
    static var shared = PlayerSDK()
    #else
    static let shared = PlayerSDK()
    #endif

    let monitor: Monitor

    init() {
        self.monitor = Monitor()
    }

}
