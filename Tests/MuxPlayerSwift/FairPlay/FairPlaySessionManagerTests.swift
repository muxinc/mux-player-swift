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
    
    override func setUp() {
        super.setUp()
    }
    
    // Also tests PlaybackOptions.rootDomain
    func testMakeLicenseDomain() throws {
        let optionsWithoutCustomDomain = PlaybackOptions()
        let defaultLicenseDomain = DefaultFPSManager.makeLicenseDomain(optionsWithoutCustomDomain.rootDomain())
        XCTAssert(
            defaultLicenseDomain == "license.mux.com",
            "Default license server is license.mux.com"
        )
        
        var optionsCustomDomain = PlaybackOptions()
        optionsCustomDomain.customDomain = "fake.custom.domain.xyz"
        let customLicenseDomain = DefaultFPSManager.makeLicenseDomain(optionsCustomDomain.rootDomain())
        XCTAssert(
            customLicenseDomain == "license.fake.custom.domain.xyz",
            "Custom license server is license.fake.custom.domain.xyz"
        )
    }
}
