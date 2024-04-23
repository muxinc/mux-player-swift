//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

class FairplaySessionManager {
    
    static let shared = FairplaySessionManager()
    
    let contentKeySession: AVContentKeySession
    let sessionDelegate: AVContentKeySessionDelegate
    
    /// Requests the App Certificate for a playback id
    func requestCertificate(playbackID: String, drmToken: String, completion: (Result<Data, Error>) -> Void) {
        // todo - request app certficate from the backend
    }
    
    public func requestLicense(spcData: Data, playbackID: String, drmToken: String?, offline: Bool, completion: (Result<Data, Error>) -> Void) {
        // todo request license from backend for the playback id, drmToken, and spc data
    }
    
    private convenience init() {
        let session = AVContentKeySession(keySystem: .fairPlayStreaming)
        let delegate = ContentKeySessionDelegate()
        
        self.init(
            contentKeySession: session,
            sessionDelegate: delegate,
            sessionDelegateQueue: DispatchQueue(label: "com.mux.player.fairplay")
        )
    }
    
    private init(
        contentKeySession: AVContentKeySession,
        sessionDelegate: AVContentKeySessionDelegate,
        sessionDelegateQueue: DispatchQueue
    ) {
        contentKeySession.setDelegate(sessionDelegate, queue: sessionDelegateQueue)
        
        self.contentKeySession = contentKeySession
        self.sessionDelegate = sessionDelegate
    }
}
