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

    var contentKeyRecipients: [any AVContentKeyRecipient] = []

    func setDelegate(
        _ delegate: (any AVContentKeySessionDelegate)?,
        queue delegateQueue: dispatch_queue_t?
    ) {
        self.delegate = delegate
    }
    
    func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        contentKeyRecipients.append(recipient)
    }
    
    func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        // no-op
    }
    
    func recreate() -> Self {
        Self()
    }

	required init() {

	}
}
