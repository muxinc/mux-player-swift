//
//  DRMTokenClaims.swift
//  MuxPlayerSwift
//

import Foundation

struct DRMTokenClaims {
    /// Seconds from license creation until expiration (when not yet played)
    let licenseExpiration: TimeInterval?
    /// Seconds from first playback until expiration
    let playDuration: TimeInterval?
    /// Whether the token is for offline use
    let offline: Bool

    /// Parses claims from a JWT's payload segment (no signature verification).
    static func from(drmToken: String) -> DRMTokenClaims? {
        let segments = drmToken.split(separator: ".")
        guard segments.count == 3 else { return nil }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad to multiple of 4
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let licenseExpiration = json["licenseExpiration"] as? TimeInterval
        let playDuration = json["playDuration"] as? TimeInterval
        let offline = json["offline"] as? Bool ?? false

        return DRMTokenClaims(
            licenseExpiration: licenseExpiration,
            playDuration: playDuration,
            offline: offline
        )
    }
}
