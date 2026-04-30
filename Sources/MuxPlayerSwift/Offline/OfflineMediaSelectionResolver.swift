//
//  OfflineMediaSelectionResolver.swift
//  MuxPlayerSwift
//

import AVFoundation
import Foundation

struct OfflineMediaSelectionResolution {
    let mediaSelections: [AVMediaSelection]?
}

enum OfflineMediaSelectionResolver {
    static func availableOptions(for asset: AVURLAsset) async throws -> OfflineMediaOptions {
        async let audio = options(for: asset, characteristic: .audible, type: .audio)
        async let subtitles = options(for: asset, characteristic: .legible, type: .subtitles)
        return try await OfflineMediaOptions(audio: audio, subtitles: subtitles)
    }

    static func resolve(
        policy: OfflineMediaSelectionPolicy,
        for asset: AVURLAsset
    ) async throws -> OfflineMediaSelectionResolution {
        switch policy {
        case .automatic:
            return OfflineMediaSelectionResolution(mediaSelections: nil)
        case .all:
            async let preferredSelection = asset.load(.preferredMediaSelection)
            async let allMediaSelections = asset.load(.allMediaSelections)
            let mediaSelections = try await [preferredSelection] + allMediaSelections
            return OfflineMediaSelectionResolution(mediaSelections: mediaSelections)
        case .languages(let audioLanguages, let subtitleLanguages):
            return try await resolveLanguages(
                audioLanguages: audioLanguages,
                subtitleLanguages: subtitleLanguages,
                for: asset
            )
        case .options(let options):
            return try await resolveExactOptions(options, for: asset)
        }
    }

    private static func resolveLanguages(
        audioLanguages: [String],
        subtitleLanguages: [String],
        for asset: AVURLAsset
    ) async throws -> OfflineMediaSelectionResolution {
        guard !audioLanguages.isEmpty || !subtitleLanguages.isEmpty else {
            return OfflineMediaSelectionResolution(mediaSelections: nil)
        }

        async let audioGroup = asset.loadMediaSelectionGroup(for: .audible)
        async let subtitleGroup = asset.loadMediaSelectionGroup(for: .legible)
        let groups = try await (audioGroup, subtitleGroup)

        let audioOptions = matchingOptions(
            languages: audioLanguages,
            group: groups.0
        )
        let requestedSubtitleOptions = matchingOptions(
            languages: subtitleLanguages,
            group: groups.1
        )

        guard (audioLanguages.isEmpty || !audioOptions.isEmpty),
              (subtitleLanguages.isEmpty || !requestedSubtitleOptions.isEmpty)
        else {
            throw OfflineMediaSelectionError.noMatchingOptions
        }

        var subtitleOptions = requestedSubtitleOptions
        for forcedSubtitleOption in forcedSubtitleOptions(
            matching: audioOptions,
            in: groups.1
        ) where !subtitleOptions.contains(forcedSubtitleOption) {
            subtitleOptions.append(forcedSubtitleOption)
        }

        let mediaSelections = try await mediaSelections(
            for: asset,
            audioOptions: audioOptions,
            audioGroup: groups.0,
            subtitleOptions: subtitleOptions,
            subtitleGroup: groups.1
        )
        guard !mediaSelections.isEmpty else {
            throw OfflineMediaSelectionError.noMatchingOptions
        }

        return OfflineMediaSelectionResolution(mediaSelections: mediaSelections)
    }

    private static func resolveExactOptions(
        _ requestedOptions: [OfflineMediaOption],
        for asset: AVURLAsset
    ) async throws -> OfflineMediaSelectionResolution {
        guard !requestedOptions.isEmpty else {
            return OfflineMediaSelectionResolution(mediaSelections: nil)
        }

        async let audioGroup = asset.loadMediaSelectionGroup(for: .audible)
        async let subtitleGroup = asset.loadMediaSelectionGroup(for: .legible)
        let groups = try await (audioGroup, subtitleGroup)

        let audioOptions = try requestedOptions
            .filter { $0.type == .audio }
            .map { try mediaSelectionOption(for: $0, in: groups.0) }
        let subtitleOptions = try requestedOptions
            .filter { $0.type == .subtitles }
            .map { try mediaSelectionOption(for: $0, in: groups.1) }

        let mediaSelections = try await mediaSelections(
            for: asset,
            audioOptions: audioOptions,
            audioGroup: groups.0,
            subtitleOptions: subtitleOptions,
            subtitleGroup: groups.1
        )

        guard !mediaSelections.isEmpty else {
            throw OfflineMediaSelectionError.noMatchingOptions
        }

        return OfflineMediaSelectionResolution(mediaSelections: mediaSelections)
    }

    private static func options(
        for asset: AVURLAsset,
        characteristic: AVMediaCharacteristic,
        type: OfflineMediaOptionType
    ) async throws -> [OfflineMediaOption] {
        guard let group = try await asset.loadMediaSelectionGroup(for: characteristic) else {
            return []
        }
        return try AVMediaSelectionGroup
            .playableMediaSelectionOptions(from: group.options)
            .map { try OfflineMediaOption(option: $0, type: type) }
    }

    private static func matchingOptions(
        languages: [String],
        group: AVMediaSelectionGroup?
    ) -> [AVMediaSelectionOption] {
        guard !languages.isEmpty, let group else { return [] }
        let playableOptions = AVMediaSelectionGroup.playableMediaSelectionOptions(from: group.options)
        return AVMediaSelectionGroup.mediaSelectionOptions(
            from: playableOptions,
            filteredAndSortedAccordingToPreferredLanguages: languages
        )
    }

    private static func forcedSubtitleOptions(
        matching audioOptions: [AVMediaSelectionOption],
        in subtitleGroup: AVMediaSelectionGroup?
    ) -> [AVMediaSelectionOption] {
        let selectedAudioLanguageSubtags = Set(
            audioOptions.compactMap {
                primaryLanguageSubtag(for: languageTag(for: $0))
            }
        )
        guard !selectedAudioLanguageSubtags.isEmpty, let subtitleGroup else { return [] }

        return AVMediaSelectionGroup
            .playableMediaSelectionOptions(from: subtitleGroup.options)
            .filter { option in
                guard option.hasMediaCharacteristic(.containsOnlyForcedSubtitles),
                      let subtitleLanguageSubtag = primaryLanguageSubtag(for: languageTag(for: option))
                else {
                    return false
                }
                return selectedAudioLanguageSubtags.contains(subtitleLanguageSubtag)
            }
    }

    private static func languageTag(for option: AVMediaSelectionOption) -> String? {
        option.extendedLanguageTag ?? option.locale?.identifier
    }

    static func primaryLanguageSubtag(for languageTag: String?) -> String? {
        guard let languageTag else { return nil }

        let normalizedTag = languageTag
            .replacingOccurrences(of: "_", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return normalizedTag
            .split(separator: "-")
            .first
            .map(String.init)
    }

    private static func mediaSelectionOption(
        for option: OfflineMediaOption,
        in group: AVMediaSelectionGroup?
    ) throws -> AVMediaSelectionOption {
        guard let group else {
            throw OfflineMediaSelectionError.optionUnavailable(option.displayName)
        }
        guard let propertyList = option.mediaSelectionPropertyList() else {
            throw OfflineMediaSelectionError.invalidOptionIdentifier(option.id)
        }
        guard let mediaSelectionOption = group.mediaSelectionOption(withPropertyList: propertyList) else {
            throw OfflineMediaSelectionError.optionUnavailable(option.displayName)
        }
        return mediaSelectionOption
    }

    private static func mediaSelections(
        for asset: AVURLAsset,
        audioOptions: [AVMediaSelectionOption],
        audioGroup: AVMediaSelectionGroup?,
        subtitleOptions: [AVMediaSelectionOption],
        subtitleGroup: AVMediaSelectionGroup?
    ) async throws -> [AVMediaSelection] {
        let preferredSelection = try await asset.load(.preferredMediaSelection)
        let audioChoices: [AVMediaSelectionOption?] = audioOptions.isEmpty ? [nil] : audioOptions
        let subtitleChoices: [AVMediaSelectionOption?] = subtitleOptions.isEmpty ? [nil] : subtitleOptions

        let requestedSelections: [AVMediaSelection] = audioChoices.flatMap { audioOption in
            subtitleChoices.compactMap { subtitleOption in
                guard let selection = preferredSelection.mutableCopy() as? AVMutableMediaSelection else {
                    return nil
                }
                if let audioGroup, let audioOption {
                    selection.select(audioOption, in: audioGroup)
                }
                if let subtitleGroup, let subtitleOption {
                    selection.select(subtitleOption, in: subtitleGroup)
                }
                return selection
            }
        }
        return [preferredSelection] + requestedSelections
    }
}

extension OfflineMediaOption {
    init(option: AVMediaSelectionOption, type: OfflineMediaOptionType) throws {
        self.init(
            id: try option.mediaSelectionIdentifier(),
            displayName: option.displayName,
            type: type,
            extendedLanguageTag: option.extendedLanguageTag,
            localeIdentifier: option.locale?.identifier,
            mediaSubTypes: option.mediaSubTypes.map { $0.fourCharacterCodeString },
            characteristics: Self.characteristics(for: option)
        )
    }

    fileprivate func mediaSelectionPropertyList() -> Any? {
        guard let data = Data(base64Encoded: id) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    }

    private static func characteristics(for option: AVMediaSelectionOption) -> [String] {
        allCharacteristics
            .filter { option.hasMediaCharacteristic($0) }
            .map(\.rawValue)
    }

    private static var allCharacteristics: [AVMediaCharacteristic] {
        [
            .audible,
            .legible,
            .visual,
            .containsOnlyForcedSubtitles,
            .transcribesSpokenDialogForAccessibility,
            .describesMusicAndSoundForAccessibility,
            .describesVideoForAccessibility,
            .easyToRead,
            .isMainProgramContent,
            .isAuxiliaryContent,
            .isOriginalContent,
            .languageTranslation,
            .dubbedTranslation,
            .voiceOverTranslation
        ]
    }
}

private extension AVMediaSelectionOption {
    func mediaSelectionIdentifier() throws -> String {
        let data = try PropertyListSerialization.data(
            fromPropertyList: propertyList(),
            format: .binary,
            options: 0
        )
        return data.base64EncodedString()
    }
}

private extension NSNumber {
    var fourCharacterCodeString: String {
        let code = uint32Value
        let bytes = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff)
        ]
        if bytes.allSatisfy({ $0 >= 32 && $0 <= 126 }),
           let string = String(bytes: bytes, encoding: .ascii) {
            return string
        }
        return "\(code)"
    }
}
