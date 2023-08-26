//
//  PlaybackURLTests.swift
//

import AVFoundation
import XCTest
@testable import MuxAVPlayerSDK

final class PlaybackURLTests: XCTestCase {
    func testPlaybackURL() throws {
        let playerItem = AVPlayerItem(
            publicPlaybackID: "abc"
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://stream.mux.com/abc.m3u8"
        )
    }
}
