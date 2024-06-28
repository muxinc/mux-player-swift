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
    private let failsWith: (any Error)!

    var logger: Logger = Logger(
        OSLog(
            subsystem: "com.mux.player",
            category: "CK"
        )
    )

    func requestCertificate(fromDomain rootDomain: String, playbackID: String, drmToken: String, completion requestCompletion: @escaping (Result<Data, any Error>) -> Void) {
        if let fakeCert = fakeCert {
            requestCompletion(Result.success(fakeCert))
        } else {
            requestCompletion(Result.failure(failsWith))
        }
    }
    
    func requestLicense(spcData: Data, playbackID: String, drmToken: String, rootDomain: String, offline _: Bool, completion requestCompletion: @escaping (Result<Data, any Error>) -> Void) {
        if let fakeLicense = fakeLicense {
            requestCompletion(Result.success(fakeLicense))
        } else {
            requestCompletion(Result.failure(failsWith))
        }
    }
    
    convenience init(fakeCert: Data, fakeLicense: Data) {
        self.init(fakeCert: fakeCert, fakeLicense: fakeLicense, failsWith: nil)
    }
    
    convenience init(failsWith: any Error) {
        self.init(fakeCert: nil, fakeLicense: nil, failsWith: failsWith)
    }
    
    private init(
        fakeCert: Data?,
        fakeLicense: Data?,
        failsWith: (any Error)?
    ) {
        self.fakeCert = fakeCert
        self.fakeLicense = fakeLicense
        self.failsWith = failsWith
    }
}
