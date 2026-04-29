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

// internal DTO for our index of downloaded assets
struct StoredAsset: Codable {
    let isComplete: Bool
    let completedWithError: Bool

    let playbackID: String
    let localPath: String?
    let readableTitle: String
    let posterDataBase64: String?
    let mediaSelectionPolicy: OfflineMediaSelectionPolicy?

    let ckcFilePath: String?
    /// For secure playback: playback token expiration
    let redownloadExpiration: Date?

    // DRM expiration fields
    /// The start time for computing license expiration
    let expireLicenseFrom: Date?
    /// Which expiration period applies
    let expirationPhase: ExpirationPhase?
    /// Seconds from license creation until expiration (from JWT licenseExpiration claim)
    let licenseExpirationSeconds: TimeInterval?
    /// Seconds from first offline playback until expiration (from JWT playDuration claim)
    let playDurationSeconds: TimeInterval?

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
            mediaSelectionPolicy: options.mediaSelectionPolicy,
            ckcFilePath: nil,
            redownloadExpiration: nil,
            expireLicenseFrom: hasDRM ? Date() : nil,
            expirationPhase: hasDRM ? .licenseExpiration : nil,
            licenseExpirationSeconds: drmClaims?.licenseExpiration,
            playDurationSeconds: drmClaims?.playDuration
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
