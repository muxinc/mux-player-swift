//
//  PlaybackURLTests.swift
//

import AVKit
import AVFoundation
import XCTest
@testable import MuxPlayerSwift

final class PlaybackURLTests: XCTestCase {
    func testPlaybackURL() throws {

        let playbackOptions = PlaybackOptions()

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
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

            let playbackURL = try XCTUnwrap(
                (playerItem.asset as? AVURLAsset)?.url
            )

            XCTAssertEqual(
                playbackURL.absoluteString,
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
            let playbackOptions = PlaybackOptions(
                minimumResolutionTier: tier
            )

            let playerItem = AVPlayerItem(
                playbackID: "abc",
                playbackOptions: playbackOptions
            )

            let playbackURL = try XCTUnwrap(
                (playerItem.asset as? AVURLAsset)?.url
            )

            XCTAssertEqual(
                playbackURL.absoluteString,
                expectedURLs[tier.queryValue]
            )
        }
    }
    
    func testRenditionOrder() throws {

        let expectedURLs: [String: String] = [
            RenditionOrder.descending.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true&rendition_order=desc",
            RenditionOrder.default.queryValue:
                "https://stream.mux.com/abc.m3u8?redundant_streams=true"
        ]

        let tiers: [RenditionOrder] = [
            .descending,
            .default
        ]

        for tier in tiers {
            let playbackOptions = PlaybackOptions(
                renditionOrder: tier
            )

            let playerItem = AVPlayerItem(
                playbackID: "abc",
                playbackOptions: playbackOptions
            )

            let playbackURL = try XCTUnwrap(
                (playerItem.asset as? AVURLAsset)?.url
            )

            XCTAssertEqual(
                playbackURL.absoluteString,
                expectedURLs[tier.queryValue]
            )
        }
    }
    
    func testMultiplePlaybackOptionParams() throws {
        let playbackOptions = PlaybackOptions(
            maximumResolutionTier: MaxResolutionTier.upTo2160p,
            minimumResolutionTier: MinResolutionTier.atLeast1440p
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )
        
        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
            "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=2160p&min_resolution=1440p"
        )
    }

    func testSingleRenditionResolutionTierOption() throws {
        let playbackOptions = PlaybackOptions(
            enableSmartCache: false,
            singleRenditionResolutionTier: .only1080p
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
            "https://stream.mux.com/abc.m3u8?redundant_streams=true&max_resolution=1080p&min_resolution=1080p"
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

        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
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

        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
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

        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
            "https://stream.play.example.com/abc.m3u8?token=WhoooopsNotAnActualToken"
        )
    }

    func testReverseProxyTargetingURL() throws {
        let playbackOptions = PlaybackOptions(
            enableSmartCache: true,
            singleRenditionResolutionTier: .only1080p
        )

        let playerItem = AVPlayerItem(
            playbackID: "abc",
            playbackOptions: playbackOptions
        )

        let playbackURL = try XCTUnwrap(
            (playerItem.asset as? AVURLAsset)?.url
        )

        XCTAssertEqual(
            playbackURL.absoluteString,
            "http://127.0.0.1:1234/abc.m3u8?redundant_streams=true&max_resolution=1080p&min_resolution=1080p&__hls_origin_url=https://stream.mux.com/abc.m3u8?redundant_streams%3Dtrue%26max_resolution%3D1080p%26min_resolution%3D1080p"
        )
    }

    func testExistingPlayerViewControllerPreparationForPlayback() throws {
        let playerViewController = AVPlayerViewController()
        playerViewController.prepare(
            playbackID: "abc",
            playbackOptions: PlaybackOptions(
                maximumResolutionTier: .upTo1080p,
                minimumResolutionTier: .atLeast540p,
                renditionOrder: .descending
            )
        )

        let item = try XCTUnwrap(
            playerViewController.player?.currentItem,
            "Expected player item"
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let components = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        )


        XCTAssertTrue(
            components.path.contains("abc")
        )

        XCTAssertNotNil(
            components.queryItems?.first(where: {
                $0.name == "max_resolution" && $0.value == "1080p"
            })
        )

        XCTAssertNotNil(
            components.queryItems?.first(where: {
                $0.name == "min_resolution" && $0.value == "540p"
            })
        )

        XCTAssertNotNil(
            components.queryItems?.first(where: {
                $0.name == "rendition_order" && $0.value == "desc"
            })
        )

        playerViewController.prepare(
            playbackID: "def",
            playbackOptions: PlaybackOptions(
                maximumResolutionTier: .upTo720p
            )
        )

        let secondItem = try XCTUnwrap(
            playerViewController.player?.currentItem,
            "Expected player item"
        )

        let secondURL = try XCTUnwrap(
            (secondItem.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let secondURLComponents = try XCTUnwrap(
            URLComponents(
                url: secondURL,
                resolvingAgainstBaseURL: false
            )
        )

        XCTAssertTrue(
            secondURLComponents.path.contains("def")
        )

        let secondURLQueryItems = try XCTUnwrap(
            secondURLComponents.queryItems,
            "Expected query items to be present"
        )

        XCTAssertNotNil(
            secondURLQueryItems.first(where: {
                $0.name == "max_resolution" && $0.value == "720p"
            })
        )

        XCTAssertNil(
            secondURLQueryItems.first(where: {
                $0.name == "min_resolution"
            })
        )

        XCTAssertNil(
            secondURLQueryItems.first(where: {
                $0.name == "rendition_order"
            })
        )
    }

    func testExistingPlayerLayerPreparationForPlayback() throws {
        let playerLayer = AVPlayerLayer()
        playerLayer.prepare(
            playbackID: "abc",
            playbackOptions: PlaybackOptions(
                maximumResolutionTier: .upTo1080p,
                minimumResolutionTier: .atLeast540p,
                renditionOrder: .descending
            )
        )

        let item = try XCTUnwrap(
            playerLayer.player?.currentItem,
            "Expected player item"
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let components = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        )


        XCTAssertTrue(
            components.path.contains("abc")
        )

        XCTAssertNotNil(
            components.queryItems?.first(where: {
                $0.name == "max_resolution" && $0.value == "1080p"
            })
        )

        XCTAssertNotNil(
            components.queryItems?.first(where: {
                $0.name == "min_resolution" && $0.value == "540p"
            })
        )

        XCTAssertNotNil(
            components.queryItems?.first(where: {
                $0.name == "rendition_order" && $0.value == "desc"
            })
        )

        playerLayer.prepare(
            playbackID: "def",
            playbackOptions: PlaybackOptions(
                maximumResolutionTier: .upTo720p
            )
        )

        let secondItem = try XCTUnwrap(
            playerLayer.player?.currentItem,
            "Expected player item"
        )

        let secondURL = try XCTUnwrap(
            (secondItem.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let secondURLComponents = try XCTUnwrap(
            URLComponents(
                url: secondURL,
                resolvingAgainstBaseURL: false
            )
        )

        XCTAssertTrue(
            secondURLComponents.path.contains("def")
        )

        let secondURLQueryItems = try XCTUnwrap(
            secondURLComponents.queryItems,
            "Expected query items to be present"
        )

        XCTAssertNotNil(
            secondURLQueryItems.first(where: {
                $0.name == "max_resolution" && $0.value == "720p"
            })
        )

        XCTAssertNil(
            secondURLQueryItems.first(where: {
                $0.name == "min_resolution"
            })
        )

        XCTAssertNil(
            secondURLQueryItems.first(where: {
                $0.name == "rendition_order"
            })
        )
    }

    func testPlaybackIDExtraction() throws {
        let playerItem = AVPlayerItem(playbackID: "abc123")

        XCTAssertEqual(playerItem.playbackID, "abc123")

        let customDomainPlayerItem = AVPlayerItem(
            playbackID: "def456",
            playbackOptions: PlaybackOptions(
                customDomain: "media.example.com"
            )
        )

        XCTAssertEqual(
            customDomainPlayerItem.playbackID,
            "def456"
        )
    }

    func testClippingAssetStartTime() throws {
        let item = AVPlayerItem(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                clipping: .init(
                    assetStartTimeInSeconds: 12
                )
            )
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let queryItems = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "asset_start_time"
            })
        )
    }

    func testClippingAssetEndTime() throws {
        let item = AVPlayerItem(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                clipping: .init(
                    assetEndTimeInSeconds: 20
                )
            )
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let queryItems = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "asset_end_time"
            })
        )
    }

    func testClippingAssetStartAndEndTime() throws {
        let item = AVPlayerItem(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                clipping: .init(
                    assetStartTimeInSeconds: 12,
                    assetEndTimeInSeconds: 20
                )
            )
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let queryItems = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "asset_start_time"
            })
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "asset_end_time"
            })
        )
    }

    func testClippingProgramStartTime() throws {
        let item = AVPlayerItem(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                clipping: InstantClipping(
                    programStartTimeEpochInSeconds: 1730214200
                )
            )
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let queryItems = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "program_start_time"
            })
        )
    }

    func testClippingProgramEndTime() throws {
        let item = AVPlayerItem(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                clipping: InstantClipping(
                    programEndTimeEpochInSeconds: 1730217200
                )
            )
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let queryItems = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "program_end_time"
            })
        )
    }

    func testClippingProgramStartAndEndTime() throws {
        let item = AVPlayerItem(
            playbackID: "abc123",
            playbackOptions: PlaybackOptions(
                clipping: InstantClipping(
                    programStartTimeEpochInSeconds: 1730214200,
                    programEndTimeEpochInSeconds: 1730217200
                )
            )
        )

        let url = try XCTUnwrap(
            (item.asset as? AVURLAsset)?.url,
            "Expected player item with URL"
        )

        let queryItems = try XCTUnwrap(
            URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "program_start_time"
            })
        )

        XCTAssertNotNil(
            queryItems.first(where: {
                $0.name == "program_end_time"
            })
        )
    }
}
