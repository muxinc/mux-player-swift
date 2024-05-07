//
//  ContentKeySessionDelegateTests.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import XCTest
@testable import MuxPlayerSwift

class ContentKeySessionDelegateTests : XCTestCase {
    
//    var sessionDelegate: ContentKeySessionDelegate<FairPlayStreamingSessionManager>!
    var testPlaybackOptionsRegistry: TestPlaybackOptionsRegistry!
    var testCredentialClient: TestFairPlayStreamingSessionCredentialClient!
    
    // object under test
    var contentKeySessionDelegate: ContentKeySessionDelegate<
        TestFairPlayStreamingSessionManager
    >!
    
    override func setUp() async throws {
        setUpForSuccess()
    }
    
    private func setUpForFailure(error: any Error) {
        testCredentialClient = TestFairPlayStreamingSessionCredentialClient(
            failsWith: error
        )
        testPlaybackOptionsRegistry = TestPlaybackOptionsRegistry()
        
        contentKeySessionDelegate = ContentKeySessionDelegate(
            credentialClient: testCredentialClient,
            optionsRegistry: testPlaybackOptionsRegistry
        )
    }
    
    private func setUpForSuccess() {
        testCredentialClient = TestFairPlayStreamingSessionCredentialClient(
            fakeCert: "default fake cert".data(using: .utf8)!,
            fakeLicense: "default fake license".data(using: .utf8)!
        )
        testPlaybackOptionsRegistry = TestPlaybackOptionsRegistry()
        
        contentKeySessionDelegate = ContentKeySessionDelegate(
            credentialClient: testCredentialClient,
            optionsRegistry: testPlaybackOptionsRegistry
        )
    }
    
    func testParsePlaybackId() throws {
       let fakeKeyUri = "skd://fake.domain/?playbackId=12345&token=unrelated-to-test"
        
    }
}
