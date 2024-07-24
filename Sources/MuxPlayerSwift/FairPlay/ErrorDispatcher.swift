//
//  ErrorDispatcher.swift
//
//

import Foundation

protocol ErrorDispatcher {
    func dispatchError(
        errorCode: String,
        errorMessage: String,
        playerObjectIdentifier: ObjectIdentifier
    )
}
