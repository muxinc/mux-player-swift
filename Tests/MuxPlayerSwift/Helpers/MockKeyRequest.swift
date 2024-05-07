//
//  MockKeyRequest.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import AVFoundation
@testable import MuxPlayerSwift

/// Mock ``KeyRequest`` which can record the methods called on it for later verification
class MockKeyRequest : KeyRequest {
    // our fake 'request' just records calls and args
    typealias InnerRequest = [[String: [Any?]]]
    
    private var fakeRequest: InnerRequest = [[:]]
    private let fakeIdentifier: Any
    
    var identifier: Any? {
        get {
            return fakeIdentifier
        }
    }
    
    func processContentKeyResponse(_ response: AVContentKeyResponse) {
        fakeRequest.append(["processContentKeyResponse": [response]])
    }
    
    func processContentKeyResponseError(_ error: any Error) {
        fakeRequest.append(["processContentKeyResponseError": [error]])
    }
    
    func makeStreamingContentKeyRequestData(
        forApp appIdentifier: Data,
        contentIdentifier: Data?,
        options: [String : Any]? = nil,
        completionHandler handler: @escaping (Data?, (any Error)?) -> Void
    ) {
        let funcName = "makeStreamingContentKeyRequestData"
        let args: [Any?] = [
            appIdentifier,
            contentIdentifier as Any,
            options as Any,
            handler
        ] as [Any?]
        
        fakeRequest.append([funcName: args])
    }
    
    init(fakeIdentifier: String = "fake-identifier") {
        self.fakeIdentifier = fakeIdentifier
    }
}
