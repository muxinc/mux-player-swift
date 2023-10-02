//
//  PlaybackURLTests.swift
//

import AVFoundation
import XCTest
@testable import MuxAVPlayerSDK

final class PlaybackURLTests: XCTestCase {
    func testPlaybackURL() throws {
        let playerItem = AVPlayerItem(
            playbackID: "abc"
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://stream.mux.com/abc.m3u8?redundant_streams=true"
        )
    }

    func testMaximumResolution() throws {
        let playbackOptions = PlaybackOptions(
            maximumResolutionTier: .upTo720p
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=720p"
        )
    }

    func testCustomDomainPlaybackURL() throws {

        let playbackOptions = PlaybackOptions(
            customDomain: "play.example.com"
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://play.example.com/abc.m3u8?redundant_streams=true"
        )
    }

    func testSignedPlaybackURL() throws {

        let playbackOptions = PlaybackOptions(
            playbackToken: "WhoooopsNotAnActualToken"
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://stream.mux.com/abc.m3u8?token=WhoooopsNotAnActualToken"
        )
    }

    func testCustomDomainSignedPlaybackURL() throws {

        let playbackOptions = PlaybackOptions(
            customDomain: "play.example.com",
            playbackToken: "WhoooopsNotAnActualToken"
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://play.example.com/abc.m3u8?token=WhoooopsNotAnActualToken"
        )
    }
}
