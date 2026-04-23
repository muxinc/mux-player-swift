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

    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
        drmAssetRegistry.addDRMAsset(urlAsset, playbackID: playbackID, options: options, rootDomain: rootDomain)
    }

    func requestCertificate(playbackID: String, online: Bool) async throws -> Data {
        try await credentialClient.requestCertificate(playbackID: playbackID, online: online)
    }

    func requestLicense(spcData: Data, playbackID: String, online: Bool) async throws -> Data {
        try await credentialClient.requestLicense(spcData: spcData, playbackID: playbackID, online: online)
    }

    func addOfflineDownloadDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
        drmAssetRegistry.addOfflineDownloadDRMAsset(urlAsset, playbackID: playbackID, options: options, rootDomain: rootDomain)
    }

    func removeOfflineDownloadSession(playbackID: String) {
        drmAssetRegistry.removeOfflineDownloadSession(playbackID: playbackID)
    }

    func addOfflinePlayDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, keyData: Data) async {
        await drmAssetRegistry.addOfflinePlayDRMAsset(urlAsset, playbackID: playbackID, keyData: keyData)
    }

    func hasOfflineDRMConfig(playbackID: String) -> Bool {
        drmAssetRegistry.hasOfflineDRMConfig(playbackID: playbackID)
    }

    func offlineKeyData(playbackID: String) -> Data? {
        drmAssetRegistry.offlineKeyData(playbackID: playbackID)
    }
    
    init(credentialClient: any FairPlayStreamingSessionCredentialClient,
         drmAssetRegistry: any DRMAssetRegistry) {
        self.credentialClient = credentialClient
        self.drmAssetRegistry = drmAssetRegistry
    }
}
