//
//  ErrorDispatcher.swift
//
//

import Foundation

protocol ErrorDispatcher {
    func dispatchApplicationCertificateRequestError(
        error: FairPlaySessionError,
        playbackID: String
    )

    func dispatchLicenseRequestError(
        error: FairPlaySessionError,
        playbackID: String
    )


    
}
