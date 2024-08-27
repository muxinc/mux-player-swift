//
//  ErrorDispatcher.swift
//
//

import Foundation

protocol ErrorDispatcher {
    func dispatchApplicationCertificateRequestError(
        _ error: FairPlaySessionError
    )

    func dispatchLicenseRequestError(
        _ error: FairPlaySessionError
    )


    
}
