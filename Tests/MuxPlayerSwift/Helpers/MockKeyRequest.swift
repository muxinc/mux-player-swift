//
//  MockKeyRequest.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import AVFoundation
@testable import MuxPlayerSwift

/// Mock ``KeyRequest`` with some basic recording & verification
class MockKeyRequest : KeyRequest {
    // our fake 'request' just records calls and args
    typealias InnerRequest = [(String, [Any?])]
    
    private var fakeRequest: InnerRequest = []
    private let fakeIdentifier: Any
    
    // MARK: Protocol impl
    
    var identifier: Any? {
        get {
            return fakeIdentifier
        }
    }
    
    func makeContentKeyResponse(data: Data) -> AVContentKeyResponse {
        // can't use the fairplay data in tests
        return AVContentKeyResponse(authorizationTokenData: "fake-token".data(using: .utf8)!)
    }
    

    func processContentKeyResponse(_ response: AVContentKeyResponse) {
        fakeRequest.append(("processContentKeyResponse", [response]))
    }
    
    func processContentKeyResponseError(_ error: any Error) {
        fakeRequest.append(("processContentKeyResponseError", [error]))
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
        
        fakeRequest.append((funcName, args))
    }
    
    // MARK: verificaitons
    
    /// Verifies that the given method was called the given number of times
    /// This can be  enough for situations where the arg values don't matter
    /// or where they'd be pretty obvious.
    /// To verify args, use ``calls``
    func verifyWasCalled(funcName: String, times: Int = 1) -> Bool {
        return fakeRequest.filter{ (f, _) in f == funcName }.count == times
    }
    
    func verifyNotCalled(funcName: String) -> Bool {
        return verifyWasCalled(funcName: funcName, times: 0)
    }
    
    var calls: [(String, [Any?])] {
        get {
            return fakeRequest
        }
    }
    
    init(fakeIdentifier: String = "fake-identifier") {
        self.fakeIdentifier = fakeIdentifier
    }
}
