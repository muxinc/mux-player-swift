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

    let reverseProxyServer: ReverseProxyServer

    init() {
        self.monitor = Monitor()
        self.reverseProxyServer = ReverseProxyServer()

        self.reverseProxyServer.start()
    }

}
