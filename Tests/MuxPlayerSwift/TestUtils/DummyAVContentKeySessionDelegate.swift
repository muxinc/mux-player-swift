//
//  File.swift
//  
//
//  Created by Emily Dixon on 5/2/24.
//

import Foundation
import AVKit

/// Dummy AVContentKeySessionDelegate. Doesn't respond to calls or do anything
class DummyAVContentKeySessionDelegate: NSObject, AVContentKeySessionDelegate {
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        // no op
    }
    
}
