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
    func requestCertificate(playbackID: String, drmKey: String, completion: (Result<Data, Error>) -> Void) {
        // todo - request app certficate from the backend
    }
    
    private init() {
        // todo - initialize the object with an AVContentKeySession
    }
}
