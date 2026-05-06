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
            stateIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if case .downloading(let progress) = state {
                    ProgressView(value: progress, total: 100)
                }
            }

            Spacer()

            actionButtons
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .notDownloaded: EmptyView()
        case .downloading: Image(systemName: "arrow.down.circle").foregroundStyle(.blue)
        case .downloaded: Image(systemName: "play.circle.fill").foregroundStyle(.blue)
        case .expired: Image(systemName: "clock.badge.exclamationmark").foregroundStyle(.orange)
        case .mustRedownload: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        case .error: Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch state {
        case .notDownloaded: "Not Downloaded"
        case .downloading(let progress): "Downloading... \(Int(progress))%"
        case .downloaded: "Downloaded"
        case .expired: "Expired"
        case .mustRedownload: "Must Redownload"
        case .error(let error): error.localizedDescription
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch state {
        case .notDownloaded:
            EmptyView()
        case .downloading:
            Button("Cancel", role: .destructive, action: onAction)
                .buttonStyle(.borderless)
        case .downloaded:
            Button("Delete", role: .destructive, action: onAction)
                .buttonStyle(.borderless)
        case .expired, .mustRedownload, .error:
            if let onSecondaryAction {
                Button("Cancel", role: .destructive, action: onSecondaryAction)
                    .buttonStyle(.borderless)
            }
            Button("Retry", action: onAction)
                .buttonStyle(.borderless)
        }
    }
}
