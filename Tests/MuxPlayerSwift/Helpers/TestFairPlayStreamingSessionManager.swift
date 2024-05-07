//
//  TestFairPlayStreamingManager.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import AVFoundation
@testable import MuxPlayerSwift

class TestFairPlayStreamingSessionManager : FairPlayStreamingSessionCredentialClient & PlaybackOptionsRegistry {
    
    let credentialClient: FairPlayStreamingSessionCredentialClient
    let optionsRegistry: PlaybackOptionsRegistry
    
    func requestCertificate(fromDomain rootDomain: String, playbackID: String, drmToken: String, completion requestCompletion: @escaping (Result<Data, any Error>) -> Void) {
        credentialClient.requestCertificate(fromDomain: rootDomain, playbackID: playbackID, drmToken: drmToken, completion: requestCompletion)
    }
   
    func requestLicense(spcData: Data, playbackID: String, drmToken: String, rootDomain: String, offline: Bool, completion requestCompletion: @escaping (Result<Data, any Error>) -> Void) {
        credentialClient.requestLicense(spcData: spcData, playbackID: playbackID, drmToken: drmToken, rootDomain: rootDomain, offline: offline, completion: requestCompletion)
    }
    
    func registerPlaybackOptions(_ opts: MuxPlayerSwift.PlaybackOptions, for playbackID: String) {
        optionsRegistry.registerPlaybackOptions(opts, for: playbackID)
    }
    
    func findRegisteredPlaybackOptions(for playbackID: String) -> MuxPlayerSwift.PlaybackOptions? {
        optionsRegistry.findRegisteredPlaybackOptions(for: playbackID)
    }
    
    func unregisterPlaybackOptions(for playbackID: String) {
        optionsRegistry.unregisterPlaybackOptions(for: playbackID)
    }
   
    init(credentialClient: any FairPlayStreamingSessionCredentialClient,
         optionsRegistry: any PlaybackOptionsRegistry) {
        self.credentialClient = credentialClient
        self.optionsRegistry = optionsRegistry
    }
}
