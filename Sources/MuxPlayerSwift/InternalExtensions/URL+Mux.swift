//
//  URL+Mux.swift
//

import Foundation

internal extension URL {
    var isReverseProxyable: Bool {
        guard let components = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false
        ) else {
            return false
        }

        return components.scheme == PlaybackURLConstants.reverseProxyScheme &&
        components.port == PlaybackURLConstants.reverseProxyPort &&
        components.host == PlaybackURLConstants.reverseProxyHost
    }

}
