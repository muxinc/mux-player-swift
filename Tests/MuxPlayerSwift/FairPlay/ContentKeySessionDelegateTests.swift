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
    
    func testKeyRequestNoPlaybackId() throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrlIncorrect()
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
        setUpForFailure(error: .unexpected(message: "fake error"))
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
        testDRMAssetRegistry.addDRMAsset(
            AVURLAsset(url: URL(string: "https://example.com/playlist.m3u8")!),
            playbackID: "fake-playback",
            options: .init(playbackToken: "playback-token", drmToken: "drm-token"),
            rootDomain: "example.com")

        contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
        
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponseError")
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "makeStreamingContentKeyRequestData")
        )
    }
    
    func testSPCForCKCFailedLicense() throws {
        setUpForFailure(error: .unexpected(message: "fake error"))
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )
        
        contentKeySessionDelegate.handleSpcObtainedFromCDM(
            spcData: "fake-spc-data".data(using: .utf8)!,
            playbackID: "fake-playback",
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
        testDRMAssetRegistry.addDRMAsset(
            AVURLAsset(url: URL(string: "https://example.com/playlist.m3u8")!),
            playbackID: "fake-playback",
            options: .init(playbackToken: "playback-token", drmToken: "drm-token"),
            rootDomain: "example.com")

        contentKeySessionDelegate.handleSpcObtainedFromCDM(
            spcData: "fake-spc-data".data(using: .utf8)!,
            playbackID: "fake-playback",
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
