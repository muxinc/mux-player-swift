//
//  FairPlaySessionManagerTests.swift
//
//
//  Created by Emily Dixon on 5/2/24.
//

import Foundation
import XCTest
import AVKit
@testable import MuxPlayerSwift

class FairPlaySessionManagerTests : XCTestCase {
    
    // mocks
    private var mockURLSession: URLSession!
    private var mockAVContentKeySession: DummyAVContentKeySession!
    
    // object under test
    private var sessionManager: FairPlaySessionManager!
    
    override func setUp() {
        super.setUp()
        
        let mockURLSessionConfig = URLSessionConfiguration.default
        mockURLSessionConfig.protocolClasses = [MockURLProtocol.self]
        self.mockURLSession = URLSession.init(configuration: mockURLSessionConfig)
        
        self.mockAVContentKeySession =  DummyAVContentKeySession(keySystem: .clearKey)
        self.sessionManager = DefaultFPSSManager(
            // .clearKey is used because .fairPlay requires a physical device
            contentKeySession: mockAVContentKeySession,
            sessionDelegate: DummyAVContentKeySessionDelegate(),
            sessionDelegateQueue: DispatchQueue(label: "com.mux.player.test.fairplay"),
            urlSession: mockURLSession
        )
    }
    
    // Also tests PlaybackOptions.rootDomain
    func testMakeLicenseDomain() throws {
        let optionsWithoutCustomDomain = PlaybackOptions()
        let defaultLicenseDomain = DefaultFPSSManager.makeLicenseDomain(optionsWithoutCustomDomain.rootDomain())
        XCTAssert(
            defaultLicenseDomain == "license.mux.com",
            "Default license server is license.mux.com"
        )
        
        var optionsCustomDomain = PlaybackOptions()
        optionsCustomDomain.customDomain = "fake.custom.domain.xyz"
        let customLicenseDomain = DefaultFPSSManager.makeLicenseDomain(optionsCustomDomain.rootDomain())
        XCTAssert(
            customLicenseDomain == "license.fake.custom.domain.xyz",
            "Custom license server is license.fake.custom.domain.xyz"
        )
    }
    
    func testMakeLicenseURL() throws {
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeLicenseDomain = "license.fake.domain.xyz"
        
        let licenseURL = DefaultFPSSManager.makeLicenseURL(
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            licenseDomain: fakeLicenseDomain
        )
        let expected = "https://\(fakeLicenseDomain)/license/fairplay/\(fakePlaybackId)?token=\(fakeDrmToken)"
        
        XCTAssertEqual(
            expected, licenseURL.absoluteString
        )
    }
    
    func testMakeAppCertificateUrl() throws {
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeLicenseDomain = "license.fake.domain.xyz"
        
        let licenseURL = DefaultFPSSManager.makeAppCertificateURL(
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            licenseDomain: fakeLicenseDomain
        )
        let expected = "https://\(fakeLicenseDomain)/appcert/fairplay/\(fakePlaybackId)?token=\(fakeDrmToken)"
        
        XCTAssertEqual(
            expected, licenseURL.absoluteString
        )
    }
    
    // TODO: Test Request Bodies too!
    
    func testRequestCertificateSuccess() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        // real app certs are opaque binary to us, the fake one can be whatever
        let fakeAppCert = "fake-application-cert-binary-data".data(using: .utf8)
        
        let requestSuccess = XCTestExpectation(description: "request certificate successfully")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            
            return (response, fakeAppCert)
        }
        
        var foundAppCert: Data?
        sessionManager.requestCertificate(
            fromDomain: fakeRootDomain,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken
        ) { result in
            guard let result = try? result.get() else {
                XCTFail("Should not report failure for the given request")
                return
            }
            
            foundAppCert = result
            requestSuccess.fulfill()
        }
        wait(for: [requestSuccess])
        XCTAssertEqual(foundAppCert, fakeAppCert)
    }
    
    func testRequestCertificateHttpError() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeHTTPStatus = 500 // all codes are handled the same way, by failing
        // real app certs are opaque binary to us, the fake one can be whatever
        
        let requestFails = XCTestExpectation(description: "request certificate successfully")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: fakeHTTPStatus,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            
            // failed requests proxied from our drm vendor have response bodies with
            //   base64 text, which we should treat as opaque (not parse or decode),
            //   since can't do anything with them and Cast logs them on the backend
            let errorBody = "failed request source text"
            let errorData = errorBody.data(using: .utf8) // crashes if processed probably
            return (
                response,
                errorData
            )
        }
        
        var reqError: Error?
        sessionManager.requestCertificate(
            fromDomain: fakeRootDomain,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken
        ) { result in
            do {
                let result = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
            
        }
        wait(for: [requestFails])
        
        guard let reqError = reqError,
              let fpsError = reqError as? FairPlaySessionError
        else {
            XCTFail("Request error was wrong type")
            return
        }
        
        if case .httpFailed(let code) = fpsError {
            XCTAssertEqual(code, fakeHTTPStatus)
        } else {
            XCTFail("HTTP failure not reported with .httpFailed()")
        }
    }
    
    func testRequestCertificateIOError() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeError = FakeError(tag: "some io fail")
        // real app certs are opaque binary to us, the fake one can be whatever
        
        let requestFails = XCTestExpectation(description: "request certificate successfully")
        MockURLProtocol.requestHandler = { request in
            throw FakeError()
        }
        
        var reqError: Error?
        sessionManager.requestCertificate(
            fromDomain: fakeRootDomain,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken
        ) { result in
            do {
                try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
        }
        wait(for: [requestFails])
        
        guard let reqError = reqError,
              let fpsError = reqError as? FairPlaySessionError
        else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .because(let cause) = fpsError else {
            XCTFail("I/O Failure should report a cause")
            return
        }
        
        // If we make it here, we succeeded
    }
    
    func testRequestCertificateBlankWithSusStatusCode() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        // In this case, there's a successful response but no body
        
        let requestFails = XCTestExpectation(description: "request certificate suspicious 200/OK should be treated as failure")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            
            return (response, nil)
        }
        
        // Expected behavior: URLTask does something odd, requestCertificate returns error
        var reqError: Error?
        sessionManager.requestCertificate(
            fromDomain: fakeRootDomain,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken
        ) { result in
            do {
                try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
                requestFails.fulfill()
            }
        }
        wait(for: [requestFails])
        
        guard let reqError = reqError,
              let fpsError = reqError as? FairPlaySessionError
        else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .unexpected(_) = fpsError else {
            XCTFail("I/O Failure should report a cause")
            return
        }
    }
    
    func testRequestLicenseSuccess() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeSpcData = "fake-spc-data".data(using: .utf8)!
        // to be returned by call under test
        let fakeLicense = "fake-license-binary-data".data(using: .utf8)
        
        let requestSuccess = XCTestExpectation(description: "request license successfully")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            
            return (response, fakeLicense)
        }
        
        var foundAppCert: Data?
        sessionManager.requestLicense(
            spcData: fakeSpcData,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            rootDomain: fakeRootDomain,
            offline: false
        ) { result in
            guard let result = try? result.get() else {
                XCTFail("Should not report failure for the given request")
                return
            }
            
            foundAppCert = result
            requestSuccess.fulfill()
        }
        wait(for: [requestSuccess])
        XCTAssertEqual(foundAppCert, fakeLicense)
    }
    
    func testLicenseRequestHttpError() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeHTTPStatus = 500 // all codes are handled the same way, by failing
        // real app certs are opaque binary to us, the fake one can be whatever
        let fakeSpcData = "fake-spc-data".data(using: .utf8)!
        // to be returned by call under test
        let fakeLicense = "fake-license-binary-data".data(using: .utf8)
        
        let requestFails = XCTestExpectation(description: "request certificate successfully")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: fakeHTTPStatus,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            
            // failed requests proxied from our drm vendor have response bodies with
            //   base64 text, which we should treat as opaque (not parse or decode),
            //   since can't do anything with them and Cast logs them on the backend
            let errorBody = "failed request source text"
            let errorData = errorBody.data(using: .utf8) // crashes if processed probably
            return (
                response,
                errorData
            )
        }
        
        var reqError: Error?
        sessionManager.requestLicense(
            spcData: fakeSpcData,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            rootDomain: fakeRootDomain,
            offline: false
        ) { result in
            do {
                let result = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
            
        }
        wait(for: [requestFails])
        
        guard let reqError = reqError,
              let fpsError = reqError as? FairPlaySessionError
        else {
            XCTFail("Request error was wrong type")
            return
        }
        
        if case .httpFailed(let code) = fpsError {
            XCTAssertEqual(code, fakeHTTPStatus)
        } else {
            XCTFail("HTTP failure not reported with .httpFailed()")
        }
    }
    
    func testRequestLicenseIOError() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeSpcData = "fake-spc-data".data(using: .utf8)!

        let requestFails = XCTestExpectation(description: "request certificate successfully")
        MockURLProtocol.requestHandler = { request in
            throw FakeError()
        }
        
        var reqError: Error?
        sessionManager.requestLicense(
            spcData: fakeSpcData,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            rootDomain: fakeRootDomain,
            offline: false
        ) { result in
            do {
                let data = try result.get()
                XCTFail("failure should have been reported, but got \(String(describing: data))")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
        }
        wait(for: [requestFails])
        
        guard let reqError = reqError,
              let fpsError = reqError as? FairPlaySessionError
        else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .because(let cause) = fpsError else {
            XCTFail("I/O Failure should report a cause")
            return
        }
        
        // If we make it here, we succeeded
    }
    
    func testRequestLicenseBlankWithSusStatusCode() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        // In this case, there's a successful response but no body
        let fakeSpcData = "fake-spc-data".data(using: .utf8)!

        let requestFails = XCTestExpectation(description: "request certificate suspicious 200/OK should be treated as failure")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            
            return (response, nil)
        }
        
        // Expected behavior: URLTask does something odd, requestCertificate returns error
        var reqError: Error?
        sessionManager.requestLicense(
            spcData: fakeSpcData,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            rootDomain: fakeRootDomain,
            offline: false
        ) { result in
            do {
                try result.get()
            } catch {
                reqError = error
                requestFails.fulfill()
            }
            XCTFail("failure should have been reported")
        }
        wait(for: [requestFails])
        
        guard let reqError = reqError,
              let fpsError = reqError as? FairPlaySessionError
        else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .unexpected(_) = fpsError else {
            XCTFail("I/O Failure should report a cause")
            return
        }
    }
}
