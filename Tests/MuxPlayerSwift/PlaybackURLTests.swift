//
//  PlaybackURLTests.swift
//

import AVFoundation
import XCTest
@testable import MuxPlayerSwift

final class PlaybackURLTests: XCTestCase {
    func testPlaybackURL() throws {

        var playbackOptions = PlaybackOptions()
        playbackOptions.disableCaching = true

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
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
            var playbackOptions = PlaybackOptions(
                maximumResolutionTier: tier
            )
            playbackOptions.disableCaching = true

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

    func testMinimumResolution() throws {

        let expectedURLs: [String: String] = [
            MinResolutionTier.atLeast480p.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&min_resolution=480p",
            MinResolutionTier.atLeast540p.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&min_resolution=540p",
            MinResolutionTier.atLeast720p.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&min_resolution=720p",
            MinResolutionTier.atLeast1080p.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&min_resolution=1080p",
            MinResolutionTier.atLeast1440p.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&min_resolution=1440p",
            MinResolutionTier.atLeast2160p.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&min_resolution=2160p",
            MinResolutionTier.default.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true"
        ]

        let tiers: [MinResolutionTier] = [
            .atLeast480p,
            .atLeast540p,
            .atLeast720p,
            .atLeast1080p,
            .atLeast1440p,
            .atLeast2160p,
            .default
        ]

        for tier in tiers {
            var playbackOptions = PlaybackOptions(
                minimumResolutionTier: tier
            )
            playbackOptions.disableCaching = true

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
    
    func testRenditionOrder() throws {

        let expectedURLs: [String: String] = [
            RenditionOrder.descending.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&rendition_order=desc",
            RenditionOrder.ascending.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&rendition_order=asc",
            RenditionOrder.default.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true"
        ]

        let tiers: [RenditionOrder] = [
            .ascending,
            .descending,
            .default
        ]

        for tier in tiers {
            var playbackOptions = PlaybackOptions(
                renditionOrder: tier
            )
            playbackOptions.disableCaching = true

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
    
    func testMultiplePlaybackOptionParams() throws {
        var playbackOptions = PlaybackOptions(
            maximumResolutionTier: MaxResolutionTier.upTo2160p,
            minimumResolutionTier: MinResolutionTier.atLeast1440p,
            renditionOrder: RenditionOrder.ascending
        )
        playbackOptions.disableCaching = true

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )
        
        XCTAssertEqual(
            (playerItem.asset as! AVURLAsset).url.absoluteString,
            "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=2160p&min_resolution=1440p&rendition_order=asc"
        )
    }
    
    func testCustomDomainPlaybackURL() throws {

        var playbackOptions = PlaybackOptions(
            customDomain: "play.example.com"
        )
        playbackOptions.disableCaching = true

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

        var playbackOptions = PlaybackOptions(
            playbackToken: "WhoooopsNotAnActualToken"
        )
        playbackOptions.disableCaching = true

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

        var playbackOptions = PlaybackOptions(
            customDomain: "play.example.com",
            playbackToken: "WhoooopsNotAnActualToken"
        )
        playbackOptions.disableCaching = true

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
