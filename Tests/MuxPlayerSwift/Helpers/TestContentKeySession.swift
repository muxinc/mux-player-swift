//
//  TestContentKeySession.swift
//
//
//  Created by Emily Dixon on 5/2/24.
//

import Foundation
import AVKit

@testable import MuxPlayerSwift

class TestContentKeySession: ContentKeyProvider {

    var delegate: (any AVContentKeySessionDelegate)?

    func setDelegate(
        _ delegate: (any AVContentKeySessionDelegate)?,
        queue delegateQueue: dispatch_queue_t?
    ) {
        self.delegate = delegate
    }
    
    func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {

    }
    
    func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        
    }
    
	init() {
	
	}
}
