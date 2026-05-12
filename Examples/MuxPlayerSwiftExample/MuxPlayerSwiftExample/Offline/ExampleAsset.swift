//
//  ExampleAsset.swift
//  MuxPlayerSwiftExample
//

import Foundation
import MuxPlayerSwift

struct ExampleAsset: Identifiable {
    let playbackID: String
    let title: String
    let playbackToken: String?
    let drmToken: String?

    var id: String { playbackID }

    init(
        playbackID: String,
        title: String,
        playbackToken: String? = nil,
        drmToken: String? = nil
    ) {
        self.playbackID = playbackID
        self.title = title
        self.playbackToken = playbackToken
        self.drmToken = drmToken
    }

    func makePlaybackOptions() -> PlaybackOptions {
        guard let playbackToken else {
            return PlaybackOptions()
        }
        guard let drmToken else {
            return PlaybackOptions(playbackToken: playbackToken)
        }
        return PlaybackOptions(playbackToken: playbackToken, drmToken: drmToken)
    }
}
