//
//  MockAVContentKeySession.swift
//
//
//  Created by Emily Dixon on 5/2/24.
//

import Foundation
import AVKit

/// Mocked AVContentKeySession with some basic recording and spying functionality
/// Use ``callsByFunc`` to get list of calls with their arguments in order
/// Mock features are written by-hand but work
/// Only methods needed for testing are mocked. Be careful.
class MockAVContentKeySession: AVContentKeySession {
    
    var callsByFuncName: [String: [Any]]
    
    override func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        callsByFuncName["addContentKeyRecipient"] = [recipient]
    }
    
    override func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        callsByFuncName["removeContentKeyRecipient"] = [recipient]
    }
}
