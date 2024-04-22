//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation

class FairplaySessionManager {
    
    static let shared = FairplaySessionManager()
    
    /// Requests the App Certificate for a playback id 
    func requestCertificate(playbackID: String, drmToken: String, completion: (Result<Data, Error>) -> Void) {
        // todo - request app certficate from the backend
    }
    
    public func requestLicense(_ spcData: Data, playbackID: String, drmToken: String?, offline: Bool, completion: (Result<Data, Error>) -> Void) {
        // todo request license from backend for the playback id, drmToken, and spc data
    }
    
    private init() {
        // todo - initialize the object with an AVContentKeySession
    }
}
