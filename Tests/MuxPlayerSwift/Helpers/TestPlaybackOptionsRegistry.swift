//
//  TestPlaybackOptionsRegistry.swift
//
//
//  Created by Emily Dixon on 5/7/24.
//

import Foundation
@testable import MuxPlayerSwift

class TestPlaybackOptionsRegistry : PlaybackOptionsRegistry {
    
    var options: [String: PlaybackOptions] = [:]
    
    func registerPlaybackOptions(_ opts: MuxPlayerSwift.PlaybackOptions, for playbackID: String) {
        options[playbackID] = opts
    }
    
    func findRegisteredPlaybackOptions(for playbackID: String) -> MuxPlayerSwift.PlaybackOptions? {
        return options[playbackID]
    }
    
    func unregisterPlaybackOptions(for playbackID: String) {
        options[playbackID] = nil
    }
    
    
}
