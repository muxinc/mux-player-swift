//
//  PlaybackURLTests.swift
//

import AVFoundation
import XCTest
@testable import MuxPlayerSwift

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

        let expectedURLs: [String: String] = [
            MaxResolutionTier.upTo720p.queryValue: "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=720p",
            MaxResolutionTier.upTo1080p.queryValue: "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=1080p",
            MaxResolutionTier.upTo1440p.queryValue: "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=1440p",
            MaxResolutionTier.upTo2160p.queryValue: "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=2160p",
            MaxResolutionTier.default.queryValue: "https://stream.mux.com/abc.m3u8?redundant_streams=true",
        ]

        let tiers: [MaxResolutionTier] = [
            .upTo720p,
            .upTo1080p,
            .upTo1440p,
            .upTo2160p,
            .default
        ]

        for tier in tiers {
            let playbackOptions = PlaybackOptions(
                maximumResolutionTier: tier
            )

            let playerItem = AVPlayerItem(
                playbackID: "abc",
                playbackOptions: playbackOptions
            )

            XCTAssertEqual(
                (playerItem.asset as! AVURLAsset).url.absoluteString,
                expectedURLs[tier.queryValue]
            )
        }
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
            "https://stream.play.example.com/abc.m3u8?redundant_streams=true"
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
            "https://stream.play.example.com/abc.m3u8?token=WhoooopsNotAnActualToken"
        )
    }
}
