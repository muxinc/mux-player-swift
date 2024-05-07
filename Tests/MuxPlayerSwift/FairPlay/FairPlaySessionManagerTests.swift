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

    
    // object under test
    private var sessionManager: FairPlayStreamingSessionManager!
    
    override func setUp() {
        super.setUp()
        let mockURLSessionConfig = URLSessionConfiguration.default
        mockURLSessionConfig.protocolClasses = [MockURLProtocol.self]
        self.mockURLSession = URLSession.init(configuration: mockURLSessionConfig)
        let session = TestContentKeySession()
        let defaultFairPlaySessionManager = DefaultFairPlayStreamingSessionManager(
            // .clearKey is used because .fairPlay requires a physical device
            contentKeySession: session,
            urlSession: mockURLSession
        )
        self.sessionManager = defaultFairPlaySessionManager
        defaultFairPlaySessionManager.sessionDelegate = ContentKeySessionDelegate(
            sessionManager: defaultFairPlaySessionManager
        )

    }
    
    // Also tests PlaybackOptions.rootDomain
    func testMakeLicenseDomain() throws {
        let optionsWithoutCustomDomain = PlaybackOptions()
        let defaultLicenseDomain = String.makeLicenseDomain(
            rootDomain: optionsWithoutCustomDomain.rootDomain()
        )
        XCTAssert(
            defaultLicenseDomain == "license.mux.com",
            "Default license server is license.mux.com"
        )
        
        var optionsCustomDomain = PlaybackOptions()
        optionsCustomDomain.customDomain = "fake.custom.domain.xyz"
        let customLicenseDomain = String.makeLicenseDomain(
            rootDomain: optionsCustomDomain.rootDomain()
        )
        XCTAssert(
            customLicenseDomain == "license.fake.custom.domain.xyz",
            "Custom license server is license.fake.custom.domain.xyz"
        )
    }
    
    func testMakeLicenseURL() throws {
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        let fakeLicenseDomain = "license.fake.domain.xyz"
        
        let licenseURL = URL(
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
        
        let licenseURL = URL(
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            applicationCertificateLicenseDomain: fakeLicenseDomain
        )
        let expected = "https://\(fakeLicenseDomain)/appcert/fairplay/\(fakePlaybackId)?token=\(fakeDrmToken)"
        
        XCTAssertEqual(
            expected, licenseURL.absoluteString
        )
    }
    
    func testAppCertificateRequestBody() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        
        var urlRequest: URLRequest!
        MockURLProtocol.requestHandler = { request in
            urlRequest = request
            // response is not part of this test
            return (HTTPURLResponse(), nil)
        }
        
        let requestEnds = XCTestExpectation(description: "request ends")
        sessionManager.requestCertificate(
            fromDomain: fakeRootDomain,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken
        ) { result in
            // we recorded the request so we should be ok
            requestEnds.fulfill()
        }
        wait(for: [requestEnds])
        
        let urlComponents = URLComponents(string: urlRequest.url!.absoluteString)!
        XCTAssertNotNil(urlComponents.queryItems)
        XCTAssert(urlComponents.queryItems!.count > 0)
        
        let tokenParam = urlComponents.queryItems!.first { it in it.name == "token"}
        let playbackID = urlRequest.url!.lastPathComponent

        XCTAssertNotNil(tokenParam)
        XCTAssertEqual(tokenParam?.name, "token")
        XCTAssertEqual(tokenParam?.value, fakeDrmToken)
        
        XCTAssertEqual(playbackID, fakePlaybackId)

        XCTAssertEqual(urlRequest.httpMethod, "GET")
        // note: url tested using testMakeAppCertificateURL
    }
    
    func testLicenseRequestBody() throws {
        let fakeRootDomain = "custom.domain.com"
        let fakePlaybackId = "fake_playback_id"
        let fakeDrmToken = "fake_drm_token"
        // real SPC's are opaque binary to us, the fake one can be whatever
        let fakeSpcData = "fake-SPC-binary-data".data(using: .utf8)!
        
        var urlRequest: URLRequest!
        MockURLProtocol.requestHandler = { request in
            urlRequest = request
            
            // response is not part of this test
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, "fake ckc data".data(using: .utf8))
        }
        
        let requestEnds = XCTestExpectation(description: "request ends")
        sessionManager.requestLicense(
            spcData: fakeSpcData,
            playbackID: fakePlaybackId,
            drmToken: fakeDrmToken,
            rootDomain: fakeRootDomain,
            offline: false
        ) { result in
            // we recorded the request so we should be ok
            requestEnds.fulfill()
        }
        wait(for: [requestEnds])
        
        let urlComponents = URLComponents(string: urlRequest.url!.absoluteString)!
        XCTAssertNotNil(urlComponents.queryItems)
        XCTAssert(urlComponents.queryItems!.count > 0)
        
        let tokenParam = urlComponents.queryItems!.first { it in it.name == "token"}
        let playbackID = urlRequest.url!.lastPathComponent

        XCTAssertNotNil(tokenParam)
        XCTAssertEqual(tokenParam?.name, "token")
        XCTAssertEqual(tokenParam?.value, fakeDrmToken)

        XCTAssertEqual(playbackID, fakePlaybackId)
        
        // unfortunately we can't test the body for some reason, it's always nil even
        //  when intercepting with URLProtocol
        //XCTAssertEqual(urlRequest.httpBody, fakeSpcData)
        
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        let headers = urlRequest.allHTTPHeaderFields
        guard let headers = headers, headers.count > 0 else {
            XCTFail("Request for License/CKC must have length and content type")
            return
        }
        let contentLengthHeader = headers["Content-Length"]
        let contentTypeHeader = headers["Content-Type"]
        XCTAssertEqual(Int(contentLengthHeader!)!, fakeSpcData.count)
        XCTAssertEqual(contentTypeHeader, "application/octet-stream")
    }
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
                _ = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
            
        }
        wait(for: [requestFails])
        
        guard let fpsError = reqError as? FairPlaySessionError else {
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
                _ = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
        }
        wait(for: [requestFails])
        
        guard let fpsError = reqError as? FairPlaySessionError else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .because(_) = fpsError else {
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
                _ = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
                requestFails.fulfill()
            }
        }
        wait(for: [requestFails])
        
        guard let fpsError = reqError as? FairPlaySessionError else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .unexpected(_) = fpsError else {
            XCTFail("An Unexpected error should be returned")
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
        // real SPCs are opaque binary to us, the fake one can be whatever
        let fakeSpcData = "fake-spc-data".data(using: .utf8)!
        
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
            //   since we can't do anything with them and Cast logs them on the backend
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
                _ = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
            
        }
        wait(for: [requestFails])
        
        guard let fpsError = reqError as? FairPlaySessionError else {
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
        
        guard let fpsError = reqError as? FairPlaySessionError else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .because(_) = fpsError else {
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
                _ = try result.get()
                XCTFail("failure should have been reported")
            } catch {
                reqError = error
            }
            requestFails.fulfill()
        }
        wait(for: [requestFails])
        
        guard let fpsError = reqError as? FairPlaySessionError else {
            XCTFail("Request error was wrong type")
            return
        }
        
        guard case .unexpected(_) = fpsError else {
            XCTFail("unexpected failure should be returned")
            return
        }
    }

    func testPlaybackOptionsRegistered() throws {

        #if DEBUG
        let mockURLSessionConfig = URLSessionConfiguration.default
        mockURLSessionConfig.protocolClasses = [MockURLProtocol.self]
        self.mockURLSession = URLSession.init(configuration: mockURLSessionConfig)
        // .clearKey is used because .fairPlay requires a physical device
        let session = AVContentKeySession(
            keySystem: .clearKey
        )
        let defaultFairPlaySessionManager = DefaultFairPlayStreamingSessionManager(
            contentKeySession: session,
            urlSession: mockURLSession
        )
        self.sessionManager = defaultFairPlaySessionManager
        let sessionDelegate = ContentKeySessionDelegate(
            sessionManager: defaultFairPlaySessionManager
        )
        defaultFairPlaySessionManager.sessionDelegate = sessionDelegate

        let fakeLicense = "fake-license-binary-data".data(using: .utf8)
        let fakeAppCert = "fake-application-cert-binary-data".data(using: .utf8)
        MockURLProtocol.requestHandler = { request in

            guard let url = request.url else {
                fatalError()
            }

            if (url.absoluteString.contains("appcert")) {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!

                return (response, fakeAppCert)
            } else {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!


                return (response, fakeLicense)
            }
        }


        PlayerSDK.shared = PlayerSDK(
            fairPlayStreamingSessionManager: defaultFairPlaySessionManager
        )

        let i = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: PlaybackOptions(
                playbackToken: "def",
                drmToken: "ghi"
            )
        )

        XCTAssertEqual(
            defaultFairPlaySessionManager.playbackOptionsByPlaybackID.count,
            1
        )
        #else
        XCTExpectFailure(
            "This test can only be run under a debug build configuration"
        )
        XCTAssert(false)
        #endif
    }
}
