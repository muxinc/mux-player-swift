//
//  RootContentView.swift
//  MuxPlayerSwiftExample
//

import SwiftUI

struct RootContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ContainerPlayer()
                } label: {
                    ExampleRow(
                        title: "Container Player Example",
                        subtitle: "Using MuxPlayerContainerViewController"
                    )
                }
                .accessibilityIdentifier("ContainerPlayerRow")

                NavigationLink {
                    SinglePlayer()
                } label: {
                    ExampleRow(
                        title: "Single Player Example",
                        subtitle: "Using AVPlayerViewController"
                    )
                }
                .accessibilityIdentifier("SinglePlayerRow")

                NavigationLink {
                    SmartCachePlayer()
                } label: {
                    ExampleRow(
                        title: "Smart Cache Example",
                        subtitle: "Using AVPlayerViewController"
                    )
                }
                .accessibilityIdentifier("SmartCachePlayerRow")

                NavigationLink {
                    SinglePlayerLayer()
                } label: {
                    ExampleRow(
                        title: "Single Player Layer Example",
                        subtitle: "Using AVPlayerLayer"
                    )
                }
                .accessibilityIdentifier("SinglePlayerLayerRow")

                NavigationLink {
                    DRMPlayer()
                } label: {
                    ExampleRow(
                        title: "Online DRM Example",
                        subtitle: "Using AVPlayerViewController"
                    )
                }
                .accessibilityIdentifier("DRMPlayerRow")
                
                NavigationLink {
                    OfflineAccessExampleView()
                } label: {
                    ExampleRow(
                        title: "Offline Playback",
                        subtitle: "Including DRM"
                    )
                }
                .accessibilityIdentifier("DRMPlayerRow")
            }
            .navigationTitle("Mux Player Swift")
        }
    }
}

#Preview {
    RootContentView()
}

private struct ExampleRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
