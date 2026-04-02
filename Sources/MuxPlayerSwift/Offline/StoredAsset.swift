//
//  StoredAsset.swift
//  MuxPlayerSwift
//
//  Extracted from DownloadManager.swift
//

import Foundation

// internal DTO for our index of downloaded assets
struct StoredAsset: Codable {
    let isComplete: Bool
    let completedWithError: Bool
    
    let playbackID: String
    let localPath: String?
    let readableTitle: String
    let posterDataBase64: String?
    let subtitleLanguages: [String]?
    let secondaryAudioLanguages: [String]?
    
    let ckcFilePath: String?
    /// For DRM keys: Either storage or play expiration depending on state
    let keyExpiration: Date?
    /// For secure playback: playback token expiration
    let redownloadExpiration: Date?
}

extension StoredAsset {
    static func forNewDownload(playbackID: String, options: DownloadOptions) -> StoredAsset {
        return StoredAsset(
            isComplete: false,
            completedWithError: false,
            playbackID: playbackID,
            localPath: nil,
            readableTitle: options.readableTitle,
            posterDataBase64: options.posterData?.base64EncodedString(),
            subtitleLanguages: options.subtitleLanguages,
            secondaryAudioLanguages: options.secondaryAudioLanguages,
            ckcFilePath: nil,
            keyExpiration: nil,
            redownloadExpiration: nil
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
