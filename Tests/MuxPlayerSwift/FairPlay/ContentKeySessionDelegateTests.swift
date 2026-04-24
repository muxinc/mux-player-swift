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
    var mockKeyStore: MockPersistedKeyStore!

    // object under test
    var contentKeySessionDelegate: ContentKeySessionDelegate<
        TestFairPlayStreamingSessionManager
    >!
    
    override func setUp() async throws {
        setUpForSuccess()
    }
    
    private func setUpForFailure(error: FairPlaySessionError) {
        setUpWith(
            credentialClient: TestFairPlayStreamingSessionCredentialClient(
                failsWith: error
            )
        )
    }

    private func setUpWith(
        credentialClient: TestFairPlayStreamingSessionCredentialClient
    ) {
        testCredentialClient = credentialClient
        testDRMAssetRegistry = TestDRMAssetRegistry()
        mockKeyStore = MockPersistedKeyStore()
        testSessionManager = TestFairPlayStreamingSessionManager(
            credentialClient: testCredentialClient,
            drmAssetRegistry: testDRMAssetRegistry
        )

        contentKeySessionDelegate = ContentKeySessionDelegate(
            sessionManager: testSessionManager,
            persistedKeyStore: mockKeyStore
        )
    }

    private func setUpForSuccess() {
        testCredentialClient = TestFairPlayStreamingSessionCredentialClient(
            fakeCert: "default fake cert".data(using: .utf8)!,
            fakeLicense: "default fake license".data(using: .utf8)!
        )

        testDRMAssetRegistry = TestDRMAssetRegistry()
        mockKeyStore = MockPersistedKeyStore()

        testSessionManager = TestFairPlayStreamingSessionManager(
            credentialClient: testCredentialClient,
            drmAssetRegistry: testDRMAssetRegistry
        )

        contentKeySessionDelegate = ContentKeySessionDelegate(
            sessionManager: testSessionManager,
            persistedKeyStore: mockKeyStore
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
        
        contentKeySessionDelegate.handleSpcObtainedFromCDMForOnlineKey(
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

        contentKeySessionDelegate.handleSpcObtainedFromCDMForOnlineKey(
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

    // MARK: - handlePersistableContentKeyRequest tests

    func testPersistableKeyRequest_NilSessionManager_Throws() async {
        contentKeySessionDelegate.sessionManager = nil
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        do {
            try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(
                mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
            )
        }
    }

    func testPersistableKeyRequest_InvalidIdentifier_Returns() async throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: 12345 // non-string identifier
        )

        try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)

        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponseError")
        )
    }

    func testPersistableKeyRequest_MissingPlaybackId_Throws() async {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrlIncorrect()
        )

        do {
            try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(
                mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
            )
        }
    }

    func testPersistableKeyRequest_ExistingPersistedKey_UsesItDirectly() async throws {
        let fakeKeyData = "persisted-key-data".data(using: .utf8)!
        mockKeyStore.persistedKeys["fake-playback"] = fakeKeyData

        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)

        // Should use persisted key directly
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "processContentKeyResponse")
        )
        // Should not request cert or license
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)")
        )
        // Should update expiration phase
        XCTAssertEqual(mockKeyStore.updatedPhases.count, 1)
        XCTAssertEqual(mockKeyStore.updatedPhases.first?.playbackID, "fake-playback")
        XCTAssertEqual(mockKeyStore.updatedPhases.first?.phase, .playDuration)
    }

    func testPersistableKeyRequest_NoPersistedKey_FetchesAndSaves() async throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)

        // Should have requested SPC and processed a response
        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "persistableContentKey(fromKeyVendorResponse:options:)")
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "processContentKeyResponse")
        )
        // Should have saved the key
        XCTAssertEqual(mockKeyStore.savedKeys.count, 1)
        XCTAssertEqual(mockKeyStore.savedKeys.first?.playbackID, "fake-playback")
    }

    func testPersistableKeyRequest_CertError_Throws() async {
        setUpWith(
            credentialClient: TestFairPlayStreamingSessionCredentialClient(
                certFailsWith: .unexpected(message: "cert error")
            )
        )
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        do {
            try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(
                mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
            )
            XCTAssertTrue(
                mockRequest.verifyNotCalled(
                    funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
                )
            )
        }
    }

    func testPersistableKeyRequest_LicenseError_Throws() async {
        setUpWith(
            credentialClient: TestFairPlayStreamingSessionCredentialClient(
                fakeCert: "fake-cert".data(using: .utf8)!,
                licenseFailsWith: .unexpected(message: "license error")
            )
        )
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        do {
            try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            // Should have gotten past cert and SPC stages
            XCTAssertTrue(
                mockRequest.verifyWasCalled(
                    funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
                )
            )
            // But should not have processed a response
            XCTAssertTrue(
                mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
            )
            // Should not have saved any key
            XCTAssertTrue(mockKeyStore.savedKeys.isEmpty)
        }
    }

    // MARK: - handleContentKeyUpdated tests

    func testContentKeyUpdated_HappyPath_SavesKey() async throws {
        let fakeKeyData = "updated-key-data".data(using: .utf8)!
        let keyIdentifier = makeFakeSkdUrl(fakePlaybackID: "fake-playback")

        try await contentKeySessionDelegate.handleContentKeyUpdated(
            keyIdentifier: keyIdentifier,
            data: fakeKeyData
        )

        XCTAssertEqual(mockKeyStore.savedKeys.count, 1)
        XCTAssertEqual(mockKeyStore.savedKeys.first?.playbackID, "fake-playback")
        XCTAssertEqual(mockKeyStore.savedKeys.first?.identifier, keyIdentifier)
        XCTAssertEqual(mockKeyStore.savedKeys.first?.data, fakeKeyData)
    }

    func testContentKeyUpdated_NonStringIdentifier_DoesNotSave() async throws {
        try await contentKeySessionDelegate.handleContentKeyUpdated(
            keyIdentifier: 12345,
            data: "some-data".data(using: .utf8)!
        )

        XCTAssertTrue(mockKeyStore.savedKeys.isEmpty)
    }

    func testContentKeyUpdated_InvalidURL_DoesNotSave() async throws {
        try await contentKeySessionDelegate.handleContentKeyUpdated(
            keyIdentifier: "not a url \n\n",
            data: "some-data".data(using: .utf8)!
        )

        XCTAssertTrue(mockKeyStore.savedKeys.isEmpty)
    }

    func testContentKeyUpdated_MissingPlaybackId_DoesNotSave() async throws {
        let keyIdentifier = makeFakeSkdUrlIncorrect()

        try await contentKeySessionDelegate.handleContentKeyUpdated(
            keyIdentifier: keyIdentifier,
            data: "some-data".data(using: .utf8)!
        )

        XCTAssertTrue(mockKeyStore.savedKeys.isEmpty)
    }

}
