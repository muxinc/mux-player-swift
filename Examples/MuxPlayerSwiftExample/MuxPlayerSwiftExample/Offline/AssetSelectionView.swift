//
//  AssetSelectionView.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import MuxPlayerSwift
import SwiftUI

struct AssetSelectionView: View {
    let assets: [ExampleAsset]
    let onAssetSelected: (ExampleAsset, OfflineMediaSelectionPolicy) -> Void

    var body: some View {
        List {
            Section {
                ForEach(assets) { asset in
                    NavigationLink {
                        AssetDownloadOptionsView(
                            asset: asset,
                            onDownload: { asset, policy in
                                onAssetSelected(asset, policy)
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.title)
                                .foregroundStyle(.primary)
                            Text(asset.playbackID)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Asset")
    }
}

struct AssetDownloadOptionsView: View {
    let asset: ExampleAsset
    let onDownload: (ExampleAsset, OfflineMediaSelectionPolicy) -> Void

    @State private var selectionMode = OfflineDownloadSelectionMode.automatic
    @State private var trackLoadState = TrackLoadState.idle
    @State private var selectedOptionIDs: Set<String> = []

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Media selection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Media selection", selection: $selectionMode) {
                        ForEach(OfflineDownloadSelectionMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if selectionMode == .custom {
                customTrackSections
            }
        }
        .navigationTitle(asset.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Download") {
                    onDownload(asset, mediaSelectionPolicy)
                }
                .disabled(isDownloadDisabled)
            }
        }
        .task(id: selectionMode) {
            if selectionMode == .custom {
                await loadMediaOptionsIfNeeded()
            }
        }
        .onChange(of: selectionMode) { newValue in
            if newValue != .custom {
                selectedOptionIDs.removeAll()
            }
        }
    }

    @ViewBuilder
    private var customTrackSections: some View {
        switch trackLoadState {
        case .idle, .loading:
            Section {
                HStack {
                    ProgressView()
                    Text("Loading tracks")
                }
            }
        case .failed(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle")
                Button("Retry") {
                    Task {
                        await loadMediaOptions(force: true)
                    }
                }
            }
        case .loaded(let options):
            if options.audio.isEmpty && options.subtitles.isEmpty {
                Section {
                    Text("No selectable tracks")
                        .foregroundStyle(.secondary)
                }
            } else {
                if !options.audio.isEmpty {
                    Section("Audio") {
                        ForEach(options.audio) { option in
                            trackRow(for: option)
                        }
                    }
                }
                if !options.subtitles.isEmpty {
                    Section("Subtitles") {
                        ForEach(options.subtitles) { option in
                            trackRow(for: option)
                        }
                    }
                }
            }
        }
    }

    private var mediaSelectionPolicy: OfflineMediaSelectionPolicy {
        switch selectionMode {
        case .automatic:
            return .automatic
        case .all:
            return .all
        case .custom:
            return .options(selectedOptions)
        }
    }

    private var isDownloadDisabled: Bool {
        selectionMode == .custom && selectedOptions.isEmpty
    }

    private var selectedOptions: [OfflineMediaOption] {
        guard case .loaded(let options) = trackLoadState else { return [] }
        return (options.audio + options.subtitles).filter {
            selectedOptionIDs.contains($0.id)
        }
    }

    private func trackRow(for option: OfflineMediaOption) -> some View {
        Button {
            if selectedOptionIDs.contains(option.id) {
                selectedOptionIDs.remove(option.id)
            } else {
                selectedOptionIDs.insert(option.id)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .foregroundStyle(.primary)
                    if !option.detailText.isEmpty {
                        Text(option.detailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: selectedOptionIDs.contains(option.id) ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
        }
        .buttonStyle(.plain)
    }

    private func loadMediaOptionsIfNeeded() async {
        guard case .idle = trackLoadState else { return }
        await loadMediaOptions(force: false)
    }

    private func loadMediaOptions(force: Bool) async {
        if !force, case .loaded = trackLoadState {
            return
        }

        trackLoadState = .loading
        do {
            let options = try await MuxOfflineAccessManager.shared.availableMediaOptions(
                playbackID: asset.playbackID,
                playbackOptions: asset.makePlaybackOptions()
            )
            trackLoadState = .loaded(options)
        } catch {
            trackLoadState = .failed(error.localizedDescription)
        }
    }
}

private enum OfflineDownloadSelectionMode: String, CaseIterable, Identifiable {
    case automatic
    case all
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .automatic:
            return "Auto"
        case .all:
            return "All"
        case .custom:
            return "Custom"
        }
    }
}

private enum TrackLoadState {
    case idle
    case loading
    case loaded(OfflineMediaOptions)
    case failed(String)
}

private extension OfflineMediaOption {
    var detailText: String {
        var details: [String] = []
        if let extendedLanguageTag {
            details.append(extendedLanguageTag)
        } else if let localeIdentifier {
            details.append(localeIdentifier)
        }
        if isForcedSubtitle {
            details.append("Forced")
        }
        if !mediaSubTypes.isEmpty {
            details.append(mediaSubTypes.joined(separator: ", "))
        }
        return details.joined(separator: " - ")
    }

    var isForcedSubtitle: Bool {
        characteristics.contains(AVMediaCharacteristic.containsOnlyForcedSubtitles.rawValue)
    }
}
