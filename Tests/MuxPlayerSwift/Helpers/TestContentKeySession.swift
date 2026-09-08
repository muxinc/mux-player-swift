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

    /// Identifiers passed to `processContentKeyRequest`, in order
    var processedKeyRequestIdentifiers: [Any?] = []
    /// Called when `processContentKeyRequest` is invoked, so tests can drive the
    /// delegate flow that a real session would kick off
    var onProcessContentKeyRequest: ((Any?) -> Void)?

    func processContentKeyRequest(withIdentifier identifier: Any?, initializationData: Data?, options: [String: Any]?) {
        processedKeyRequestIdentifiers.append(identifier)
        onProcessContentKeyRequest?(identifier)
    }

    /// Sessions handed out by `recreate()`, in order
    var recreatedSessions: [TestContentKeySession] = []
    /// Applied to each session `recreate()` produces, so a test can set up
    /// expectations on a session it doesn't create itself
    var configureRecreatedSession: ((TestContentKeySession) -> Void)?

    func recreate() -> Self {
        let session = Self()
        session.configureRecreatedSession = configureRecreatedSession
        configureRecreatedSession?(session)
        recreatedSessions.append(session)
        return session
    }

	required init() {

	}
}
