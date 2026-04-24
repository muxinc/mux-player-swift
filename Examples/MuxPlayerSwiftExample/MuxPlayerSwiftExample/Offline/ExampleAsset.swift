//
//  ExampleAsset.swift
//  MuxPlayerSwiftExample
//

import Foundation

struct ExampleAsset: Identifiable {
    let playbackID: String
    let title: String
    let languages: String?
    let playbackToken: String?
    let drmToken: String?

    var id: String { playbackID }

    init(
        playbackID: String,
        title: String,
        languages: String? = nil,
        playbackToken: String? = nil,
        drmToken: String? = nil
    ) {
        self.playbackID = playbackID
        self.title = title
        self.languages = languages
        self.playbackToken = playbackToken
        self.drmToken = drmToken
    }
}
