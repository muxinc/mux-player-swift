//
//  TestFairPlayStreamingManager.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import AVFoundation
import os
@testable import MuxPlayerSwift

class TestFairPlayStreamingSessionManager : FairPlayStreamingSessionCredentialClient & DRMAssetRegistry {
    
    let credentialClient: FairPlayStreamingSessionCredentialClient
    let drmAssetRegistry: DRMAssetRegistry

    var logger: Logger = Logger(
        OSLog(
            subsystem: "com.mux.player",
            category: "CK"
        )
    )

    func requestCertificate(playbackID: String, completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void) {
        credentialClient.requestCertificate(playbackID: playbackID, completion: requestCompletion)
    }

    func requestLicense(spcData: Data, playbackID: String, offline: Bool, completion requestCompletion: @escaping (Result<Data, FairPlaySessionError>) -> Void) {
        credentialClient.requestLicense(spcData: spcData, playbackID: playbackID, offline: offline, completion: requestCompletion)
    }

    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
        drmAssetRegistry.addDRMAsset(urlAsset, playbackID: playbackID, options: options, rootDomain: rootDomain)
    }
   
    init(credentialClient: any FairPlayStreamingSessionCredentialClient,
         drmAssetRegistry: any DRMAssetRegistry) {
        self.credentialClient = credentialClient
        self.drmAssetRegistry = drmAssetRegistry
    }
}
