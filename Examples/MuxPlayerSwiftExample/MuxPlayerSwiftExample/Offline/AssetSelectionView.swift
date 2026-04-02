//
//  AssetSelectionView.swift
//  MuxPlayerSwiftExample
//

import SwiftUI

struct AssetSelectionView: View {
    let assets: [ExampleAsset]
    let onAssetSelected: (ExampleAsset) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(assets) { asset in
            Button {
                onAssetSelected(asset)
                dismiss()
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
        .navigationTitle("Select Asset to Download")
    }
}
