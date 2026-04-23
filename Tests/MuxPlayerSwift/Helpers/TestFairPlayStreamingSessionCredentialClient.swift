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
    private let failsWith: FairPlaySessionError!

    var logger: Logger = Logger(
        OSLog(
            subsystem: "com.mux.player",
            category: "CK"
        )
    )

    func requestCertificate(playbackID: String, online: Bool) async throws -> Data {
        if let fakeCert = fakeCert {
            return fakeCert
        } else {
            throw failsWith
        }
    }

    func requestLicense(spcData: Data, playbackID: String, online: Bool) async throws -> Data {
        if let fakeLicense = fakeLicense {
            return fakeLicense
        } else {
            throw failsWith
        }
    }
    
    convenience init(fakeCert: Data, fakeLicense: Data) {
        self.init(fakeCert: fakeCert, fakeLicense: fakeLicense, failsWith: nil)
    }
    
    convenience init(failsWith: FairPlaySessionError) {
        self.init(fakeCert: nil, fakeLicense: nil, failsWith: failsWith)
    }
    
    private init(
        fakeCert: Data?,
        fakeLicense: Data?,
        failsWith: FairPlaySessionError?
    ) {
        self.fakeCert = fakeCert
        self.fakeLicense = fakeLicense
        self.failsWith = failsWith
    }
}
