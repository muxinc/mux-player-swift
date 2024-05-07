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
    
    func testKeyRequestNoPlaybackId() throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(
                fakePlaybackID: makeFakeSkdUrlIncorrect()
            )
        )
        
        contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
        
        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "processContentKeyResponseError"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "makeStreamingContentKeyRequestData")
        )
    }
    
    func testKeyRequestCertError() throws {
        setUpForFailure(error: FakeError(tag: "fake error"))
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )
        
        contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "processContentKeyResponseError"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "makeStreamingContentKeyRequestData")
        )
    }
    
    func testKeyRequestHappyPath() throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(
                fakePlaybackID: "fake-playback"
            )
        )
        testPlaybackOptionsRegistry.registerPlaybackOptions(
            PlaybackOptions(playbackToken: "playback-token", drmToken: "drm-token"),
            for: "fake-playback"
        )
        
        contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
        
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponseError")
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "makeStreamingContentKeyRequestData")
        )
    }
    
    func testSPCForCKCFailedLicense() throws {
        setUpForFailure(error: FakeError(tag: "fake error"))
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )
        
        contentKeySessionDelegate.handleSpcObtainedFromCDM(
            spcData: "fake-spc-data".data(using: .utf8)!,
            playbackID: "fake-playback",
            drmToken: "fake-drm-token",
            rootDomain: "mux.com",
            request: mockRequest
        )
        
        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "processContentKeyResponseError"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
        )
    }
    
    func testSPCForCKCHappyPath() throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(
                fakePlaybackID: "fake-playback"
            )
        )
        testPlaybackOptionsRegistry.registerPlaybackOptions(
            PlaybackOptions(playbackToken: "playback-token", drmToken: "drm-token"),
            for: "fake-playback"
        )
        
        contentKeySessionDelegate.handleSpcObtainedFromCDM(
            spcData: "fake-spc-data".data(using: .utf8)!,
            playbackID: "fake-playback",
            drmToken: "fake-drm-token",
            rootDomain: "mux.com",
            request: mockRequest
        )
        
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponseError")
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "processContentKeyResponse")
        )
    }
    
}
