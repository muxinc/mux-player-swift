//
//  PlayerSDK.swift
//

import Foundation
import os

// internal class to manage dependency injection
class PlayerSDK {

    static let shared = PlayerSDK()

    let monitor: Monitor

    let diagnosticsLogger: Logger

    let abrLogger: Logger

    let reverseProxyServer: ReverseProxyServer

    init() {
        self.monitor = Monitor()
        self.diagnosticsLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "Diagnostics"
            )
        )

        #if DEBUG
        self.abrLogger = Logger(
            OSLog(
                subsystem: "com.mux.player",
                category: "ABR"
            )
        )
        #else
        self.abrLogger = Logger(
            .disabled
        )
        #endif

        self.reverseProxyServer = ReverseProxyServer()

        self.reverseProxyServer.start()
    }

}
