//
//  ContentKeySessionDelegateTests.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import AVFoundation
import Foundation
import XCTest
@testable import MuxPlayerSwift

class ContentKeySessionDelegateTests : XCTestCase {
    
    var testDRMAssetRegistry: TestDRMAssetRegistry!
    var testCredentialClient: TestFairPlayStreamingSessionCredentialClient!
    var testSessionManager: TestFairPlayStreamingSessionManager!
    
    // object under test
    var contentKeySessionDelegate: ContentKeySessionDelegate<
        TestFairPlayStreamingSessionManager
    >!
    
    override func setUp() async throws {
        setUpForSuccess()
    }
    
    private func setUpForFailure(error: FairPlaySessionError) {
        testCredentialClient = TestFairPlayStreamingSessionCredentialClient(
            failsWith: error
        )
        testDRMAssetRegistry = TestDRMAssetRegistry()
        testSessionManager = TestFairPlayStreamingSessionManager(
            credentialClient: testCredentialClient,
            drmAssetRegistry: testDRMAssetRegistry
        )
        
        contentKeySessionDelegate = ContentKeySessionDelegate(
            sessionManager: testSessionManager  
        )
    }
    
    private func setUpForSuccess() {
        testCredentialClient = TestFairPlayStreamingSessionCredentialClient(
            fakeCert: "default fake cert".data(using: .utf8)!,
            fakeLicense: "default fake license".data(using: .utf8)!
        )
        
        testDRMAssetRegistry = TestDRMAssetRegistry()

        testSessionManager = TestFairPlayStreamingSessionManager(
            credentialClient: testCredentialClient,
            drmAssetRegistry: testDRMAssetRegistry
        )
        
        contentKeySessionDelegate = ContentKeySessionDelegate(
            sessionManager: testSessionManager  
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
    
    func testKeyRequestNoPlaybackId() async throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrlIncorrect()
        )

        do {
            try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
        } catch {
            // expected
        }

        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "processContentKeyResponseError"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "makeStreamingContentKeyRequestData")
        )
    }
    
    func testKeyRequestCertError() async throws {
        setUpForFailure(error: .unexpected(message: "fake error"))
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        do {
            try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            // expected
        }
    }
    
    func testKeyRequestHappyPath() async throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(
                fakePlaybackID: "fake-playback"
            )
        )
        testDRMAssetRegistry.addDRMAsset(
            AVURLAsset(url: URL(string: "https://example.com/playlist.m3u8")!),
            playbackID: "fake-playback",
            options: .init(playbackToken: "playback-token", drmToken: "drm-token"),
            rootDomain: "example.com")

        try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)

        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponseError")
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)")
        )
    }
    
    // handleSpcObtainedFromCDMForOnlineKey was removed during async refactor;
    // its logic is now inlined in handleContentKeyRequest, tested above.
    
}
