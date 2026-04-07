//
//  DownloadAssetRow.swift
//  MuxPlayerSwiftExample
//

import SwiftUI

struct DownloadAssetRow: View {
    let title: String
    let state: AssetDownloadState
    var onTap: (() -> Void)? = nil
    var onAction: () -> Void
    var onSecondaryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                statusText

                if case .downloading(let progress) = state {
                    ProgressView(value: progress, total: 100)
                }
            }

            Spacer()

            actionButtons
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .notDownloaded:
            EmptyView()
        case .downloading:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.blue)
        case .downloaded:
            Image(systemName: "play.circle.fill")
                .foregroundStyle(.blue)
        case .mustRedownload:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch state {
        case .notDownloaded:
            Text("Not Downloaded")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .downloading(let progress):
            Text("Downloading... \(Int(progress))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .downloaded:
            Text("Downloaded")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .mustRedownload:
            Text("Must Redownload")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .error(let error):
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch state {
        case .notDownloaded:
            EmptyView()
        case .downloading:
            Button("Cancel", role: .destructive) { onAction() }
                .buttonStyle(.borderless)
        case .downloaded:
            Button("Delete", role: .destructive) { onAction() }
                .buttonStyle(.borderless)
        case .mustRedownload, .error:
            if let onSecondaryAction {
                Button("Cancel", role: .destructive) { onSecondaryAction() }
                    .buttonStyle(.borderless)
            }
            Button("Retry") { onAction() }
                .buttonStyle(.borderless)
        }
    }
}
