//
//  OfflineMediaSelectionResolver.swift
//  MuxPlayerSwift
//

import AVFoundation
import Foundation

enum OfflineMediaSelectionResolver {
    static func allMediaSelections(for asset: AVURLAsset) async throws -> [AVMediaSelection] {
        async let preferredSelection = asset.load(.preferredMediaSelection)
        async let allMediaSelections = asset.load(.allMediaSelections)
        return try await [preferredSelection] + allMediaSelections
    }

    static func mediaSelectionDescription(_ mediaSelection: AVMediaSelection) async -> String {
        var descriptions: [String] = []
        guard let asset = mediaSelection.asset else {
            return "asset=nil"
        }

        do {
            if let audioGroup = try await asset.loadMediaSelectionGroup(for: .audible),
               let selectedAudio = mediaSelection.selectedMediaOption(in: audioGroup) {
                descriptions.append("audio=\(optionDescription(selectedAudio))")
            } else {
                descriptions.append("audio=nil")
            }

            if let subtitleGroup = try await asset.loadMediaSelectionGroup(for: .legible),
               let selectedSubtitle = mediaSelection.selectedMediaOption(in: subtitleGroup) {
                descriptions.append("subtitles=\(optionDescription(selectedSubtitle))")
            } else {
                descriptions.append("subtitles=nil")
            }
        } catch {
            descriptions.append("error=\(error.localizedDescription)")
        }

        return descriptions.joined(separator: " ")
    }

    static func cachedMediaSelectionCounts(for asset: AVURLAsset) async throws -> (audio: Int, subtitles: Int) {
        guard let cache = asset.assetCache else {
            return (audio: 0, subtitles: 0)
        }

        async let audioCount = cachedOptionCount(
            for: asset,
            cache: cache,
            characteristic: .audible
        )
        async let subtitleCount = cachedOptionCount(
            for: asset,
            cache: cache,
            characteristic: .legible
        )

        return try await (audio: audioCount, subtitles: subtitleCount)
    }

    static func selectedCachedOption<Option: Equatable>(
        preferredOption: Option?,
        cachedOptions: [Option],
        fallbackToFirstCachedOption: Bool
    ) -> Option? {
        if let preferredOption, cachedOptions.contains(preferredOption) {
            return preferredOption
        }
        guard fallbackToFirstCachedOption else {
            return nil
        }
        return cachedOptions.first
    }

    private static func cachedOptionCount(
        for asset: AVURLAsset,
        cache: AVAssetCache,
        characteristic: AVMediaCharacteristic
    ) async throws -> Int {
        guard let group = try await asset.loadMediaSelectionGroup(for: characteristic) else {
            return 0
        }
        return cache.mediaSelectionOptions(in: group).count
    }

    private static func optionDescription(_ option: AVMediaSelectionOption) -> String {
        let language = option.extendedLanguageTag ?? option.locale?.identifier ?? "unknown"
        return "\(option.displayName) [\(language)]"
    }
}
