//
//  MockAVContentKeySession.swift
//
//
//  Created by Emily Dixon on 5/2/24.
//

import Foundation
import AVKit

/// Dummy AVContentKeySession that does nothing
class DummyAVContentKeySession: AVContentKeySession {
    
    
    override func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
    }
    
    override func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
    }
}
