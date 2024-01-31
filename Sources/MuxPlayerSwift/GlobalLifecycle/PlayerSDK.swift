//
//  PlayerSDK.swift
//

import Foundation

// internal class to manage dependency injection
class PlayerSDK {

    static let shared = PlayerSDK()

    let monitor: Monitor

    let reverseProxyServer: ReverseProxyServer

    init() {
        self.monitor = Monitor()
        self.reverseProxyServer = ReverseProxyServer()

        self.reverseProxyServer.start()
    }

}
