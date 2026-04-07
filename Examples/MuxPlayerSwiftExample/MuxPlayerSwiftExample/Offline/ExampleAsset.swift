//
//  ExampleAsset.swift
//  MuxPlayerSwiftExample
//

import Foundation

struct ExampleAsset: Identifiable {
    let playbackID: String
    let title: String
    let languages: String? = nil

    let playbackToken: String? = nil
    let drmToken: String? = nil

    var id: String { playbackID }
}
