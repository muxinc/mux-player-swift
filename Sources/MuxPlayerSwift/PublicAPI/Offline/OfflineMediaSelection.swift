//
//  OfflineMediaSelection.swift
//  MuxPlayerSwift
//

import Foundation

/// The kind of offline media option exposed for download selection.
public enum OfflineMediaOptionType: String, Codable, Equatable {
    case audio
    case subtitles
}

/// A discoverable media option that can be included in an offline download.
public struct OfflineMediaOption: Codable, Equatable, Identifiable {
    /// Opaque identifier for passing this option back to ``OfflineMediaSelectionPolicy/options(_:)``.
    public let id: String
    /// Display name supplied by AVFoundation for the current system locale.
    public let displayName: String
    /// Whether this option represents audio or subtitles.
    public let type: OfflineMediaOptionType
    /// BCP 47 language tag, when available.
    public let extendedLanguageTag: String?
    /// Locale identifier, when available.
    public let localeIdentifier: String?
    /// Media subtype FourCC values, when AVFoundation exposes them.
    public let mediaSubTypes: [String]
    /// Raw AVFoundation media characteristic values for advanced filtering.
    public let characteristics: [String]

    public init(
        id: String,
        displayName: String,
        type: OfflineMediaOptionType,
        extendedLanguageTag: String? = nil,
        localeIdentifier: String? = nil,
        mediaSubTypes: [String] = [],
        characteristics: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.type = type
        self.extendedLanguageTag = extendedLanguageTag
        self.localeIdentifier = localeIdentifier
        self.mediaSubTypes = mediaSubTypes
        self.characteristics = characteristics
    }
}

/// Media options available for an asset.
public struct OfflineMediaOptions: Codable, Equatable {
    public let audio: [OfflineMediaOption]
    public let subtitles: [OfflineMediaOption]

    public init(audio: [OfflineMediaOption], subtitles: [OfflineMediaOption]) {
        self.audio = audio
        self.subtitles = subtitles
    }
}

/// Describes which media selections should be included in an offline download.
public enum OfflineMediaSelectionPolicy: Codable, Equatable {
    /// Preserve AVFoundation's default offline-download media selection behavior.
    case automatic
    /// Include every playable audio and subtitle media selection.
    case all
    /// Include media selections matching the requested BCP 47 language tags.
    case languages(audio: [String], subtitles: [String])
    /// Include exact options returned from ``MuxOfflineAccessManager/availableMediaOptions(playbackID:playbackOptions:)``.
    case options([OfflineMediaOption])
}

public enum OfflineMediaSelectionError: Error, Equatable {
    case invalidOptionIdentifier(String)
    case optionUnavailable(String)
    case noMatchingOptions
}

extension OfflineMediaSelectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidOptionIdentifier(let identifier):
            return "Invalid offline media option identifier: \(identifier)"
        case .optionUnavailable(let name):
            return "Offline media option is unavailable for this asset: \(name)"
        case .noMatchingOptions:
            return "No media options matched the requested offline media selection policy."
        }
    }
}
