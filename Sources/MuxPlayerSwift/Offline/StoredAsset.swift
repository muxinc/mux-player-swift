//
//  StoredAsset.swift
//  MuxPlayerSwift
//
//  Extracted from DownloadManager.swift
//

import Foundation

enum ExpirationPhase: String, Codable {
    /// Expiration is based on licenseExpiration (not yet played offline)
    case licenseExpiration
    /// Expiration is based on playDuration (played at least once offline)
    case playDuration
}

#if os(iOS)

// internal DTO for our index of downloaded assets
struct StoredAsset: Codable {
    var isComplete: Bool
    var completedWithError: Bool

    var playbackID: String
    var localPath: String?
    var readableTitle: String
    var posterDataBase64: String?

    var ckcFilePath: String?
    /// For secure playback: playback token expiration
    var redownloadExpiration: Date?

    // DRM expiration fields
    /// The start time for computing license expiration
    var expireLicenseFrom: Date?
    /// Which expiration period applies
    var expirationPhase: ExpirationPhase?
    /// Seconds from license creation until expiration (from JWT licenseExpiration claim)
    var licenseExpirationSeconds: TimeInterval?
    /// Seconds from first offline playback until expiration (from JWT playDuration claim)
    var playDurationSeconds: TimeInterval?

    /// The `skd://` key URI this asset's content key was requested under, as
    /// provided by AVFoundation during the download. Renewing the license later
    /// requires re-requesting the key under this exact identifier, because the
    /// content key is bound to it. Absent for downloads made before we started
    /// recording it, which therefore can't be renewed.
    var keyIdentifier: String?

    func isExpired(at now: Date = Date()) -> Bool {
        guard let expireLicenseFrom else { return false }

        let duration: TimeInterval?
        switch expirationPhase {
        case .playDuration:
            duration = playDurationSeconds
        case .licenseExpiration:
            duration = licenseExpirationSeconds
        case nil:
            return false
        }

        guard let duration else { return false }
        return now > expireLicenseFrom.addingTimeInterval(duration)
    }
}

extension StoredAsset {
    static func forNewDownload(
        playbackID: String,
        options: DownloadOptions,
        drmClaims: DRMTokenClaims? = nil
    ) -> StoredAsset {
        let hasDRM = drmClaims != nil
        return StoredAsset(
            isComplete: false,
            completedWithError: false,
            playbackID: playbackID,
            localPath: nil,
            readableTitle: options.readableTitle,
            posterDataBase64: options.posterData?.base64EncodedString(),
            ckcFilePath: nil,
            redownloadExpiration: nil,
            expireLicenseFrom: hasDRM ? Date() : nil,
            expirationPhase: hasDRM ? .licenseExpiration : nil,
            licenseExpirationSeconds: drmClaims?.licenseExpiration,
            playDurationSeconds: drmClaims?.playDuration,
            keyIdentifier: nil
        )
    }
}

extension StoredAsset: CustomDebugStringConvertible {
    var debugDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data: Data
        do {
            data = try encoder.encode(self)
        } catch {
            return "StoredAsset(playbackID: \(playbackID), encoding failed: \(error))"
        }

        guard let jsonString = String(data: data, encoding: .utf8) else {
            return "StoredAsset(playbackID: \(playbackID), encoding failed)"
        }

        return jsonString
    }
}

#endif
