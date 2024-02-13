//
//  PlayerSDK.swift
//

import Foundation

// internal class to manage dependency injection
class PlayerSDK {

    static let shared = PlayerSDK()

    let monitor: Monitor

    init() {
        self.monitor = Monitor()
    }

}
