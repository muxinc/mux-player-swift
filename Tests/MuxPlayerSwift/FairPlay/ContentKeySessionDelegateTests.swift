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
    var mockOnlineCache: MockOnlineLicenseCache!

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
        mockOnlineCache = MockOnlineLicenseCache()
        testSessionManager = TestFairPlayStreamingSessionManager(
            credentialClient: testCredentialClient,
            drmAssetRegistry: testDRMAssetRegistry
        )

        contentKeySessionDelegate = ContentKeySessionDelegate(
            sessionManager: testSessionManager,
            persistedKeyStore: mockKeyStore,
            onlineLicenseCache: mockOnlineCache
        )
    }

    private func setUpForSuccess() {
        testCredentialClient = TestFairPlayStreamingSessionCredentialClient(
            fakeCert: "default fake cert".data(using: .utf8)!,
            fakeLicense: "default fake license".data(using: .utf8)!
        )

        testDRMAssetRegistry = TestDRMAssetRegistry()
        mockKeyStore = MockPersistedKeyStore()
        mockOnlineCache = MockOnlineLicenseCache()

        testSessionManager = TestFairPlayStreamingSessionManager(
            credentialClient: testCredentialClient,
            drmAssetRegistry: testDRMAssetRegistry
        )

        contentKeySessionDelegate = ContentKeySessionDelegate(
            sessionManager: testSessionManager,
            persistedKeyStore: mockKeyStore,
            onlineLicenseCache: mockOnlineCache
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
    
    func testKeyRequestNoPlaybackId() async {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrlIncorrect()
        )

        do {
            try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
        } catch {
            // error is acceptable here too
        }

        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "processContentKeyResponseError"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
    }

    // An online key request now defers to the persistable-key flow (so the
    // resulting license can be cached). It should request a persistable
    // key and do no further work on this request.
    func testKeyRequest_DefersToPersistableForCaching() async throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)

        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "respondByPersistableContentKeyRequestOnAnyOS")
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
        )
    }

    // When the persistable request can't be made (e.g. AirPlay / no storage
    // directory), we fall back to a one-shot online key.
    func testKeyRequest_PersistableUnavailable_FallsBackToOneShot() async throws {
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )
        mockRequest.persistableRequestError = FakeError()

        try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)

        XCTAssertTrue(
            mockRequest.verifyNotCalled(funcName: "processContentKeyResponseError")
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "processContentKeyResponse")
        )
    }

    func testKeyRequest_OneShotFallback_CertError() async {
        setUpWith(
            credentialClient: TestFairPlayStreamingSessionCredentialClient(
                certFailsWith: .unexpected(message: "cert error")
            )
        )
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )
        mockRequest.persistableRequestError = FakeError()

        do {
            try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(
                mockRequest.verifyNotCalled(
                    funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
                )
            )
            XCTAssertTrue(
                mockRequest.verifyNotCalled(funcName: "processContentKeyResponse")
            )
        }
    }

    func testKeyRequest_OneShotFallback_LicenseError() async {
        setUpWith(
            credentialClient: TestFairPlayStreamingSessionCredentialClient(
                fakeCert: "fake-cert".data(using: .utf8)!,
                licenseFailsWith: .unexpected(message: "license error")
            )
        )
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )
        mockRequest.persistableRequestError = FakeError()

        do {
            try await contentKeySessionDelegate.handleContentKeyRequest(request: mockRequest)
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
        }
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
        testDRMAssetRegistry.offlineConfigured = true
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
        testDRMAssetRegistry.offlineConfigured = true
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
        testDRMAssetRegistry.offlineConfigured = true
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
        testDRMAssetRegistry.offlineConfigured = true
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

    // MARK: - Online license caching

    func testOnlinePersistableKeyRequest_CacheHit_UsesCachedLicenseNoNetwork() async throws {
        let token = "online-token"
        testDRMAssetRegistry.onlineToken = token
        let fingerprint = ContentKeySessionDelegate<TestFairPlayStreamingSessionManager>.fingerprint(forToken: token, rootDomain: "mux.com")
        let cachedLicense = "cached-license".data(using: .utf8)!
        mockOnlineCache.cached["fake-playback"] = (cachedLicense, fingerprint)

        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)

        // Served from cache: no cert/license network round trip, nothing stored.
        XCTAssertTrue(mockRequest.verifyWasCalled(funcName: "processContentKeyResponse"))
        XCTAssertTrue(
            mockRequest.verifyNotCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
        XCTAssertTrue(mockOnlineCache.storedCalls.isEmpty)
    }

    func testOnlinePersistableKeyRequest_CacheMiss_FetchesAndCaches() async throws {
        let token = "online-token"
        testDRMAssetRegistry.onlineToken = token

        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)

        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
        XCTAssertTrue(
            mockRequest.verifyWasCalled(funcName: "persistableContentKey(fromKeyVendorResponse:options:)")
        )
        XCTAssertTrue(mockRequest.verifyWasCalled(funcName: "processContentKeyResponse"))

        // Cached under the current token's fingerprint; not saved to the offline store.
        XCTAssertEqual(mockOnlineCache.storedCalls.count, 1)
        XCTAssertEqual(mockOnlineCache.storedCalls.first?.playbackID, "fake-playback")
        XCTAssertEqual(
            mockOnlineCache.storedCalls.first?.fingerprint,
            ContentKeySessionDelegate<TestFairPlayStreamingSessionManager>.fingerprint(forToken: token, rootDomain: "mux.com")
        )
        XCTAssertTrue(mockKeyStore.savedKeys.isEmpty)
    }

    func testOnlinePersistableKeyRequest_TokenChanged_Refetches() async throws {
        // A stale entry cached under an old token must not be served when the app
        // supplies a new token; we re-fetch and re-cache under the new one.
        let oldFingerprint = ContentKeySessionDelegate<TestFairPlayStreamingSessionManager>.fingerprint(forToken: "old-token", rootDomain: "mux.com")
        mockOnlineCache.cached["fake-playback"] = ("stale-license".data(using: .utf8)!, oldFingerprint)

        let newToken = "new-token"
        testDRMAssetRegistry.onlineToken = newToken

        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)

        XCTAssertTrue(
            mockRequest.verifyWasCalled(
                funcName: "makeStreamingContentKeyRequestData(forApp:contentIdentifier:options:)"
            )
        )
        XCTAssertEqual(mockOnlineCache.storedCalls.count, 1)
        XCTAssertEqual(
            mockOnlineCache.storedCalls.first?.fingerprint,
            ContentKeySessionDelegate<TestFairPlayStreamingSessionManager>.fingerprint(forToken: newToken, rootDomain: "mux.com")
        )
    }

    func testOnlinePersistableKeyRequest_CertError_Throws() async {
        setUpWith(
            credentialClient: TestFairPlayStreamingSessionCredentialClient(
                certFailsWith: .unexpected(message: "cert error")
            )
        )
        testDRMAssetRegistry.onlineToken = "online-token"
        let mockRequest = MockKeyRequest(
            fakeIdentifier: makeFakeSkdUrl(fakePlaybackID: "fake-playback")
        )

        do {
            try await contentKeySessionDelegate.handlePersistableContentKeyRequest(request: mockRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockRequest.verifyNotCalled(funcName: "processContentKeyResponse"))
            XCTAssertTrue(mockOnlineCache.storedCalls.isEmpty)
        }
    }

    // MARK: - handleContentKeyUpdated tests

    func testContentKeyUpdated_OfflineAsset_SavesToDownloadStore() async throws {
        testDRMAssetRegistry.offlineConfigured = true
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
        XCTAssertTrue(mockOnlineCache.storedCalls.isEmpty)
    }

    func testContentKeyUpdated_OnlineAsset_UpdatesOnlineCache() async throws {
        // Online asset (no offline config): an updated persistable key must go to
        // the online license cache, not the offline download store.
        testDRMAssetRegistry.onlineToken = "online-token"
        let fakeKeyData = "updated-online-key".data(using: .utf8)!
        let keyIdentifier = makeFakeSkdUrl(fakePlaybackID: "fake-playback")

        try await contentKeySessionDelegate.handleContentKeyUpdated(
            keyIdentifier: keyIdentifier,
            data: fakeKeyData
        )

        XCTAssertTrue(mockKeyStore.savedKeys.isEmpty)
        XCTAssertEqual(mockOnlineCache.storedCalls.count, 1)
        XCTAssertEqual(mockOnlineCache.storedCalls.first?.playbackID, "fake-playback")
        XCTAssertEqual(mockOnlineCache.storedCalls.first?.ckc, fakeKeyData)
        XCTAssertEqual(
            mockOnlineCache.storedCalls.first?.fingerprint,
            ContentKeySessionDelegate<TestFairPlayStreamingSessionManager>.fingerprint(forToken: "online-token", rootDomain: "mux.com")
        )
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
