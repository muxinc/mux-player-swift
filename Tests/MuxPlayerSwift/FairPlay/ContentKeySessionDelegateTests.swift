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
    
    private func makeFakeSkdUrl(fakePlaybackID: String) -> String {
        return "skd://fake.domain/?playbackId=\(fakePlaybackID)&token=unrelated-to-test"
    }
    
    private func makeFakeSkdUrlIncorrect() -> String {
        return "skd://fake.domain/?token=unrelated-to-test"
    }

    func testParsePlaybackId() throws {
        let fakePlaybackID = "fake-playback-id"
        let fakeKeyUri = URL(
            string: makeFakeSkdUrl(fakePlaybackID: fakePlaybackID)
        )!
        
        let foundPlaybackID = contentKeySessionDelegate.parsePlaybackId(
            fromSkdLocation: fakeKeyUri
        )
        
        XCTAssertEqual(fakePlaybackID, foundPlaybackID)
    }
    
    func testNoPlaybackId() throws {
        let fakeRequest = MockKeyRequest(fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: makeFakeSkdUrlIncorrect()))
        
        contentKeySessionDelegate.handleContentKeyRequest(request: fakeRequest)
    }
}
