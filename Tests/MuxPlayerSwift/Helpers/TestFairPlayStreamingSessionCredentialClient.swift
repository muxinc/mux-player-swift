//
//  TestFairPlayStreamingCredentialsClient.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
@testable import MuxPlayerSwift

/// Testing version of the FairPlayStreamingSessionCredentialClient`
/// This version does not interact with the network at all, it just signals
/// sucess or failure as-configured
class TestFairPlayStreamingSessionCredentialClient: FairPlayStreamingSessionCredentialClient {
    
    private let fakeCert: Data!
    private let fakeLicense: Data!
    private let failsWith: (any Error)?
    
    func requestCertificate(fromDomain rootDomain: String, playbackID: String, drmToken: String, completion requestCompletion: @escaping (Result<Data, any Error>) -> Void) {
        <#code#>
    }
    
    func requestLicense(spcData: Data, playbackID: String, drmToken: String, rootDomain: String, offline _: Bool, completion requestCompletion: @escaping (Result<Data, any Error>) -> Void) {
        <#code#>
    }
    
    convenience init(fakeCert: Data,
         fakeLicense: Data) {
        self.init(fakeCert: fakeCert, fakeLicense: fakeLicense, failsWith: nil)
    }
    
    convenience init(failsWith: any Error) {
        self.init(failsWith: failsWith)
    }
    
    private init(
        fakeCert: Data!,
        fakeLicense: Data!,
        failsWith: (any Error)?
    ) {
        self.fakeCert = fakeCert
        self.fakeLicense = fakeLicense
        self.failsWith = failsWith
    }
}
