//
//  FairPlaySessionManagerTests.swift
//
//
//  Created by Emily Dixon on 5/2/24.
//

import Foundation
import XCTest
@testable import MuxPlayerSwift

class FairPlaySessionManagerTests : XCTestCase {
    
    private var mockURLSession: URLSession = URLSession.shared
    
    override func setUp() {
        super.setUp()
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
}
