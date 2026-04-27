//
//  TestFairPlayStreamingCredentialsClient.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
import os
@testable import MuxPlayerSwift

/// Testing version of the FairPlayStreamingSessionCredentialClient`
/// This version does not interact with the network at all, it just signals
/// sucess or failure as-configured
class TestFairPlayStreamingSessionCredentialClient: FairPlayStreamingSessionCredentialClient {

    private let fakeCert: Data?
    private let fakeLicense: Data?
    private let certFailsWith: FairPlaySessionError?
    private let licenseFailsWith: FairPlaySessionError?

    var logger: Logger = Logger(
        OSLog(
            subsystem: "com.mux.player",
            category: "CK"
        )
    )

    func requestCertificate(playbackID: String) async throws -> Data {
        if let fakeCert {
            return fakeCert
        } else if let certFailsWith {
            throw certFailsWith
        } else {
            throw FairPlaySessionError.unexpected(message: "No fake cert or error configured")
        }
    }

    func requestLicence(spcData: Data, playbackID: String) async throws -> Data {
        if let fakeLicense {
            return fakeLicense
        } else if let licenseFailsWith {
            throw licenseFailsWith
        } else {
            throw FairPlaySessionError.unexpected(message: "No fake license or error configured")
        }
    }


    convenience init(fakeCert: Data, fakeLicense: Data) {
        self.init(fakeCert: fakeCert, fakeLicense: fakeLicense, certFailsWith: nil, licenseFailsWith: nil)
    }

    convenience init(failsWith: FairPlaySessionError) {
        self.init(fakeCert: nil, fakeLicense: nil, certFailsWith: failsWith, licenseFailsWith: failsWith)
    }

    convenience init(certFailsWith: FairPlaySessionError) {
        self.init(fakeCert: nil, fakeLicense: nil, certFailsWith: certFailsWith, licenseFailsWith: nil)
    }

    convenience init(fakeCert: Data, licenseFailsWith: FairPlaySessionError) {
        self.init(fakeCert: fakeCert, fakeLicense: nil, certFailsWith: nil, licenseFailsWith: licenseFailsWith)
    }

    private init(
        fakeCert: Data?,
        fakeLicense: Data?,
        certFailsWith: FairPlaySessionError?,
        licenseFailsWith: FairPlaySessionError?
    ) {
        self.fakeCert = fakeCert
        self.fakeLicense = fakeLicense
        self.certFailsWith = certFailsWith
        self.licenseFailsWith = licenseFailsWith
    }
}
