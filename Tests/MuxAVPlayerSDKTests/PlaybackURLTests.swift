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

    func testCustomDomainPlaybackURL() throws {
        let playerItem = AVPlayerItem(
            publicPlaybackID: "abc",
            customDomain: URL(string: "https://play.example.com")!
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://play.example.com/abc.m3u8"
        )
    }

    func testSignedPlaybackURL() throws {
        let playerItem = AVPlayerItem(
            signedPlaybackID: "abc",
            token: "WhoooopsNotAnActualToken"
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://stream.mux.com/abc.m3u8?token=WhoooopsNotAnActualToken"
        )
    }

    func testCustomDomainSignedPlaybackURL() throws {
        let playerItem = AVPlayerItem(
            signedPlaybackID: "abc",
            token: "WhoooopsNotAnActualToken",
            customDomain: URL(string:"https://play.example.com")!
        )

        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://play.example.com/abc.m3u8?token=WhoooopsNotAnActualToken"
        )
    }
}
