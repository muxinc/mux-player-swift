//
//  PlaylistLocalURLMapperTests.swift
//
//

import Foundation
import XCTest

@testable import MuxPlayerSwift

class PlaylistLocalURLMapperTests: XCTestCase {

    func testMultivariantPlaylistLocalURLMapping() throws {
        let originalMultivariantPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:5
        #EXT-X-INDEPENDENT-SEGMENTS
        #EXT-X-STREAM-INF:BANDWIDTH=2493700,AVERAGE-BANDWIDTH=2493700,CODECS="mp4a.40.2,avc1.640020",RESOLUTION=1280x720,CLOSED-CAPTIONS=NONE
        https://manifest-gcp-us-east1-vop1.fastly.mux.com/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfMGJjZDYyN2Q2ZDdlMWI1ZGVmZDUyZjYzMzcwNjczZjIyNTMxNjZkODAwZjJhY2UxOTQ2OGZhZjY1ZWIwZDZjZg==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=1625800,AVERAGE-BANDWIDTH=1625800,CODECS="mp4a.40.2,avc1.640020",RESOLUTION=960x540,CLOSED-CAPTIONS=NONE
        https://manifest-gcp-us-east1-vop1.fastly.mux.com/u88kdFa9NkMUJuHYfTwEMkIPqSIuvH4XbYcEo5LACwr400G019FlUZyXIgnzgrKo7E101LVqHEe1brzm8FccuJX1HkULIkqBGhv3XbUWJsKojQ/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfNGIyYTkwZmZlNGQ3Yzk0YWY4ZjgwMGQ2ZmFkMjgwNzAyMjBiYWFmMTljZGMyMmQ3MTM1MThmZTU2NTkwNDY1Nw==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=4712400,AVERAGE-BANDWIDTH=4712400,CODECS="mp4a.40.2,avc1.64002a",RESOLUTION=1920x1080,CLOSED-CAPTIONS=NONE
        https://manifest-gcp-us-east1-vop1.fastly.mux.com/cI43QOYIuATEQKttu3mi02a21mIpxeWGHduV02GxFL4ROyeTik2yK2zzhWabitgOmf1XPeOoyZ43oOrfqWYoMZClDUf4yOwAD01/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfMWZkMWJkZWM0ZjZjNjdlYzk0NWI1MTNkNzUyOTVlNjlkMGEzMTgyZGY3N2VmZWNhNzQ4ZDMyNmZkNGFkMjE3Zg==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=917400,AVERAGE-BANDWIDTH=917400,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=640x360,CLOSED-CAPTIONS=NONE
        https://manifest-gcp-us-east1-vop1.fastly.mux.com/5Hzb6h901VHRod6XTUrq9HGgwJ02KNzFWedkrun7wGhgFkhrkpKP1EBPvbPfCK00IvMEMOHDJYUuS02z100VKLhyOIolJ8HwYjoOQXLaRLhxylvI/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfZGVhNjY2MmQwYjhmNDYxYmVlMGMwMmIxYzMzYzU1ZDlhNDE4NjA5MmI3MmM4NTRjMWM5ODEzMmJmYTg2ZmUyNA==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=595100,AVERAGE-BANDWIDTH=595100,CODECS="mp4a.40.2,avc1.64001e",RESOLUTION=480x270,CLOSED-CAPTIONS=NONE
        https://manifest-gcp-us-east1-vop1.fastly.mux.com/iko00FBOhHXJjvCJFgfcKn2qtBja7gm9EWPXYYQMf01bSp8jmX3O01cUAIBRiq00koqjv00jZPZry02B4jUAMCnfzIyGInJVDLZd7d/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfOGFiZjJiNjJjMTQzNWM3Yzk4OGQyNGU3MzE2MDYzMTA5ZjNiMTdkODIzMzdmNzkwYjk3NzgwNTcwOTc4MjU0NQ==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        """

        let expectedMappedMultivarantPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:5
        #EXT-X-INDEPENDENT-SEGMENTS
        #EXT-X-STREAM-INF:BANDWIDTH=2493700,AVERAGE-BANDWIDTH=2493700,CODECS="mp4a.40.2,avc1.640020",RESOLUTION=1280x720,CLOSED-CAPTIONS=NONE
        http://127.0.0.1:1234/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfMGJjZDYyN2Q2ZDdlMWI1ZGVmZDUyZjYzMzcwNjczZjIyNTMxNjZkODAwZjJhY2UxOTQ2OGZhZjY1ZWIwZDZjZg==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk&__hls_origin_url=https://manifest-gcp-us-east1-vop1.fastly.mux.com/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfMGJjZDYyN2Q2ZDdlMWI1ZGVmZDUyZjYzMzcwNjczZjIyNTMxNjZkODAwZjJhY2UxOTQ2OGZhZjY1ZWIwZDZjZg==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=1625800,AVERAGE-BANDWIDTH=1625800,CODECS="mp4a.40.2,avc1.640020",RESOLUTION=960x540,CLOSED-CAPTIONS=NONE
        http://127.0.0.1:1234/u88kdFa9NkMUJuHYfTwEMkIPqSIuvH4XbYcEo5LACwr400G019FlUZyXIgnzgrKo7E101LVqHEe1brzm8FccuJX1HkULIkqBGhv3XbUWJsKojQ/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfNGIyYTkwZmZlNGQ3Yzk0YWY4ZjgwMGQ2ZmFkMjgwNzAyMjBiYWFmMTljZGMyMmQ3MTM1MThmZTU2NTkwNDY1Nw==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk&__hls_origin_url=https://manifest-gcp-us-east1-vop1.fastly.mux.com/u88kdFa9NkMUJuHYfTwEMkIPqSIuvH4XbYcEo5LACwr400G019FlUZyXIgnzgrKo7E101LVqHEe1brzm8FccuJX1HkULIkqBGhv3XbUWJsKojQ/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfNGIyYTkwZmZlNGQ3Yzk0YWY4ZjgwMGQ2ZmFkMjgwNzAyMjBiYWFmMTljZGMyMmQ3MTM1MThmZTU2NTkwNDY1Nw==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=4712400,AVERAGE-BANDWIDTH=4712400,CODECS="mp4a.40.2,avc1.64002a",RESOLUTION=1920x1080,CLOSED-CAPTIONS=NONE
        http://127.0.0.1:1234/cI43QOYIuATEQKttu3mi02a21mIpxeWGHduV02GxFL4ROyeTik2yK2zzhWabitgOmf1XPeOoyZ43oOrfqWYoMZClDUf4yOwAD01/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfMWZkMWJkZWM0ZjZjNjdlYzk0NWI1MTNkNzUyOTVlNjlkMGEzMTgyZGY3N2VmZWNhNzQ4ZDMyNmZkNGFkMjE3Zg==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk&__hls_origin_url=https://manifest-gcp-us-east1-vop1.fastly.mux.com/cI43QOYIuATEQKttu3mi02a21mIpxeWGHduV02GxFL4ROyeTik2yK2zzhWabitgOmf1XPeOoyZ43oOrfqWYoMZClDUf4yOwAD01/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfMWZkMWJkZWM0ZjZjNjdlYzk0NWI1MTNkNzUyOTVlNjlkMGEzMTgyZGY3N2VmZWNhNzQ4ZDMyNmZkNGFkMjE3Zg==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=917400,AVERAGE-BANDWIDTH=917400,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=640x360,CLOSED-CAPTIONS=NONE
        http://127.0.0.1:1234/5Hzb6h901VHRod6XTUrq9HGgwJ02KNzFWedkrun7wGhgFkhrkpKP1EBPvbPfCK00IvMEMOHDJYUuS02z100VKLhyOIolJ8HwYjoOQXLaRLhxylvI/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfZGVhNjY2MmQwYjhmNDYxYmVlMGMwMmIxYzMzYzU1ZDlhNDE4NjA5MmI3MmM4NTRjMWM5ODEzMmJmYTg2ZmUyNA==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk&__hls_origin_url=https://manifest-gcp-us-east1-vop1.fastly.mux.com/5Hzb6h901VHRod6XTUrq9HGgwJ02KNzFWedkrun7wGhgFkhrkpKP1EBPvbPfCK00IvMEMOHDJYUuS02z100VKLhyOIolJ8HwYjoOQXLaRLhxylvI/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfZGVhNjY2MmQwYjhmNDYxYmVlMGMwMmIxYzMzYzU1ZDlhNDE4NjA5MmI3MmM4NTRjMWM5ODEzMmJmYTg2ZmUyNA==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        #EXT-X-STREAM-INF:BANDWIDTH=595100,AVERAGE-BANDWIDTH=595100,CODECS="mp4a.40.2,avc1.64001e",RESOLUTION=480x270,CLOSED-CAPTIONS=NONE
        http://127.0.0.1:1234/iko00FBOhHXJjvCJFgfcKn2qtBja7gm9EWPXYYQMf01bSp8jmX3O01cUAIBRiq00koqjv00jZPZry02B4jUAMCnfzIyGInJVDLZd7d/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfOGFiZjJiNjJjMTQzNWM3Yzk4OGQyNGU3MzE2MDYzMTA5ZjNiMTdkODIzMzdmNzkwYjk3NzgwNTcwOTc4MjU0NQ==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk&__hls_origin_url=https://manifest-gcp-us-east1-vop1.fastly.mux.com/iko00FBOhHXJjvCJFgfcKn2qtBja7gm9EWPXYYQMf01bSp8jmX3O01cUAIBRiq00koqjv00jZPZry02B4jUAMCnfzIyGInJVDLZd7d/rendition.m3u8?cdn=fastly&expires=1708365600&skid=default&signature=NjVkMzk3MjBfOGFiZjJiNjJjMTQzNWM3Yzk4OGQyNGU3MzE2MDYzMTA5ZjNiMTdkODIzMzdmNzkwYjk3NzgwNTcwOTc4MjU0NQ==&vsid=8Iw6mvr7mGWpU4MkpUdLjwd1pULkM01cNB8eICCQyucjeZhoK1TDipXenu7pAPVPTvWtRbLU00Yxk
        """

        let mapper = ReverseProxyServer.PlaylistLocalURLMapper()


        let encodedOriginalPlaylist = try XCTUnwrap(
            originalMultivariantPlaylist.data(
                using: .utf8
            ),
            "Couldn't encode original multivariant playlist"
        )

        let playlistOriginURL = try XCTUnwrap(
            URL(string: "https://stream.mux.com/a4nOgmxGWg6gULfcBbAa00gXyfcwPnAFldF8RdsNyk8M.m3u8"),
            "Couldn't create manifest origin URL"
        )

        let encodedMappedMultivariantPlaylist = try XCTUnwrap(
            mapper.processEncodedPlaylist(
                encodedOriginalPlaylist,
                playlistOriginURL: playlistOriginURL
            ),
            "Couldn't map to local URLs in multivariant playlist"
        )

        let mappedMultivariantPlaylist = try XCTUnwrap(
            String(
                data: encodedMappedMultivariantPlaylist,
                encoding: .utf8
            )?.removingPercentEncoding,
            "Couldn't decode multivariant playlist"
        )

        XCTAssertEqual(
            mappedMultivariantPlaylist,
            expectedMappedMultivarantPlaylist
        )
    }

    func testTransportStreamRenditionPlaylistPlaylistLocalURLMapping() throws {
        let originalRenditionPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:6
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/JNsWzeS01dx24HM3zilrng400O5Fw4euDtRvGFv7BuURYjm1QWCvTlZOAJv7HSZQVjZ3p2DmGLB8tWj6S3R5IW83U3lb3WRhzkiTrpfCWHKeY/0.ts?skid=default&signature=NjYzNDQ1MjBfYjYyN2FjY2JjYWE3NGE3OTM5NjUzMDU3MGYzYjg5ZDU3MTYwYzgyNzUwMGVhYWJiYjIyNzM4MTU3YTI3NDZhZQ==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/JNsWzeS01dx24HM3zilrng400O5Fw4euDtRvGFv7BuURYjm1QWCvTlZOAJv7HSZQVjZ3p2DmGLB8tWj6S3R5IW83U3lb3WRhzkiTrpfCWHKeY/1.ts?skid=default&signature=NjYzNDQ1MjBfMzBjYTYxYmRmNTc5MWIyNzFiMDkyNjI4MGFkZWJlMTQ5OGFiZWQ1MDRiYjkwMjBjOWUzNGViZmQ2Y2FhNjIyYw==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/L4cdUJY8t8g2uevcOQOn3hfdxdwz02iFPAaWz00Z7cHewjqO00MhlOgPShV01OGsfMBZkSReuBXcDLY45asjqxdmfjVNcwVBNv2dY165dPco01RA/2.ts?skid=default&signature=NjYzNDQ1MjBfMzk3ZDU2ODgzZWUyYjVkNjdjZDY2ZGRiMDhmMzRmMzE0NmVlZjg0OGYwYmUyYWFlYTY5ZTE3MTk0MWM1MTBkOA==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/fvJht9xWvuYIONSoqqTggSc9PabvbVcdLmRzOZBuchhXtBVVx0276R2swE9Iv00NyFMPSskd6bE00Nn02ir7U6QbO3ELZsYzv02fh1R8b5BHNMkg/3.ts?skid=default&signature=NjYzNDQ1MjBfOWNiYjZmMGYwMDU3NDJmYzg3MTdlNDJiNWJkZWYxYWE5OWY5OTAwMDFiYzQzMzQ4Yzc1ZGY3NjIzNzQwYjQ3MA==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:3.85717,
        https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/4.ts?skid=default&signature=NjYzNDQ1MjBfNzAwYWIxMmY0NWIxMGViY2FhNDE3MmFlNmUwMmE1OGRjZmJhMTY1MDAxYTBiOWQ5YjA1MzczZjNkMDQ4YjRmMg==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXT-X-ENDLIST
        """

        let expectedMappedRenditionPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:6
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/JNsWzeS01dx24HM3zilrng400O5Fw4euDtRvGFv7BuURYjm1QWCvTlZOAJv7HSZQVjZ3p2DmGLB8tWj6S3R5IW83U3lb3WRhzkiTrpfCWHKeY/0.ts?skid=default&signature=NjYzNDQ1MjBfYjYyN2FjY2JjYWE3NGE3OTM5NjUzMDU3MGYzYjg5ZDU3MTYwYzgyNzUwMGVhYWJiYjIyNzM4MTU3YTI3NDZhZQ==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE&__hls_origin_url=https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/JNsWzeS01dx24HM3zilrng400O5Fw4euDtRvGFv7BuURYjm1QWCvTlZOAJv7HSZQVjZ3p2DmGLB8tWj6S3R5IW83U3lb3WRhzkiTrpfCWHKeY/0.ts?skid=default&signature=NjYzNDQ1MjBfYjYyN2FjY2JjYWE3NGE3OTM5NjUzMDU3MGYzYjg5ZDU3MTYwYzgyNzUwMGVhYWJiYjIyNzM4MTU3YTI3NDZhZQ==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/JNsWzeS01dx24HM3zilrng400O5Fw4euDtRvGFv7BuURYjm1QWCvTlZOAJv7HSZQVjZ3p2DmGLB8tWj6S3R5IW83U3lb3WRhzkiTrpfCWHKeY/1.ts?skid=default&signature=NjYzNDQ1MjBfMzBjYTYxYmRmNTc5MWIyNzFiMDkyNjI4MGFkZWJlMTQ5OGFiZWQ1MDRiYjkwMjBjOWUzNGViZmQ2Y2FhNjIyYw==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE&__hls_origin_url=https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/JNsWzeS01dx24HM3zilrng400O5Fw4euDtRvGFv7BuURYjm1QWCvTlZOAJv7HSZQVjZ3p2DmGLB8tWj6S3R5IW83U3lb3WRhzkiTrpfCWHKeY/1.ts?skid=default&signature=NjYzNDQ1MjBfMzBjYTYxYmRmNTc5MWIyNzFiMDkyNjI4MGFkZWJlMTQ5OGFiZWQ1MDRiYjkwMjBjOWUzNGViZmQ2Y2FhNjIyYw==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/L4cdUJY8t8g2uevcOQOn3hfdxdwz02iFPAaWz00Z7cHewjqO00MhlOgPShV01OGsfMBZkSReuBXcDLY45asjqxdmfjVNcwVBNv2dY165dPco01RA/2.ts?skid=default&signature=NjYzNDQ1MjBfMzk3ZDU2ODgzZWUyYjVkNjdjZDY2ZGRiMDhmMzRmMzE0NmVlZjg0OGYwYmUyYWFlYTY5ZTE3MTk0MWM1MTBkOA==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE&__hls_origin_url=https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/L4cdUJY8t8g2uevcOQOn3hfdxdwz02iFPAaWz00Z7cHewjqO00MhlOgPShV01OGsfMBZkSReuBXcDLY45asjqxdmfjVNcwVBNv2dY165dPco01RA/2.ts?skid=default&signature=NjYzNDQ1MjBfMzk3ZDU2ODgzZWUyYjVkNjdjZDY2ZGRiMDhmMzRmMzE0NmVlZjg0OGYwYmUyYWFlYTY5ZTE3MTk0MWM1MTBkOA==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/fvJht9xWvuYIONSoqqTggSc9PabvbVcdLmRzOZBuchhXtBVVx0276R2swE9Iv00NyFMPSskd6bE00Nn02ir7U6QbO3ELZsYzv02fh1R8b5BHNMkg/3.ts?skid=default&signature=NjYzNDQ1MjBfOWNiYjZmMGYwMDU3NDJmYzg3MTdlNDJiNWJkZWYxYWE5OWY5OTAwMDFiYzQzMzQ4Yzc1ZGY3NjIzNzQwYjQ3MA==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE&__hls_origin_url=https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/fvJht9xWvuYIONSoqqTggSc9PabvbVcdLmRzOZBuchhXtBVVx0276R2swE9Iv00NyFMPSskd6bE00Nn02ir7U6QbO3ELZsYzv02fh1R8b5BHNMkg/3.ts?skid=default&signature=NjYzNDQ1MjBfOWNiYjZmMGYwMDU3NDJmYzg3MTdlNDJiNWJkZWYxYWE5OWY5OTAwMDFiYzQzMzQ4Yzc1ZGY3NjIzNzQwYjQ3MA==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXTINF:3.85717,
        http://127.0.0.1:1234/v1/chunk/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/4.ts?skid=default&signature=NjYzNDQ1MjBfNzAwYWIxMmY0NWIxMGViY2FhNDE3MmFlNmUwMmE1OGRjZmJhMTY1MDAxYTBiOWQ5YjA1MzczZjNkMDQ4YjRmMg==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE&__hls_origin_url=https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/4.ts?skid=default&signature=NjYzNDQ1MjBfNzAwYWIxMmY0NWIxMGViY2FhNDE3MmFlNmUwMmE1OGRjZmJhMTY1MDAxYTBiOWQ5YjA1MzczZjNkMDQ4YjRmMg==&zone=1&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE
        #EXT-X-ENDLIST
        """

        let mapper = ReverseProxyServer.PlaylistLocalURLMapper()

        let encodedOriginalPlaylist = try XCTUnwrap(
            originalRenditionPlaylist.data(
                using: .utf8
            ),
            "Couldn't encode original rendition playlist"
        )

        let playlistOriginURL = try XCTUnwrap(
            URL(string: "https://manifest-gcp-us-east1-vop1.cfcdn.mux.com/w7aPwt8ZueCTvWOdX8OjshX7ipMHxnEFg3LgFtFxH016QQE6MZ5h3K02TSXKnhoi00H5sQY74Z6UC5sfvRzsws5YhA4caNfqTiL6rpDHEqjH9Y/rendition.m3u8?cdn=cloudflare&expires=1714701600&skid=default&signature=NjYzNDQ1MjBfYzc5OTQ3YjEzMWY0YzlhN2VmMDZlYTc0MDI0ZTJhMjA1MjQ4MjM3NTQ2MjNkYTg4MzdkNjNjZmU0NzAzNzhmOA==&vsid=sHyWqRsgf013tXi5EvVRwRAbU8nNXcf01z5eD3ki302U00JLMobx023G2022aRKEyVkBCVgx02NCoVJnLE"),
            "Couldn't create manifest origin URL"
        )

        let encodedMappedRenditionPlaylist = try XCTUnwrap(
            mapper.processEncodedPlaylist(
                encodedOriginalPlaylist,
                playlistOriginURL: playlistOriginURL
            ),
            "Couldn't map to local URLs in rendition playlist"
        )

        let mappedRenditionPlaylist = try XCTUnwrap(
            String(
                data: encodedMappedRenditionPlaylist,
                encoding: .utf8
            )?.removingPercentEncoding,
            "Couldn't decode rendition playlist"
        )

        XCTAssertEqual(
            mappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines).count,
            expectedMappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines).count
        )

        for index in 0..<mappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines).count {
            XCTAssertEqual(
                mappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines)[index],
                expectedMappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines)[index]
            )
        }

        XCTAssertEqual(
            mappedRenditionPlaylist,
            expectedMappedRenditionPlaylist
        )
    }

    func testCommonMediaApplicationFormatRenditionPlaylistPlaylistLocalURLMapping() throws {
        let originalRenditionPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:7
        #EXT-X-TARGETDURATION:5
        #EXT-X-MAP:URI="https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/18446744073709551615.m4s?skid=default&signature=NjYzNDQ1MjBfY2NiNDg1YWE0M2RiOTg5Nzc1NDJmYWVhZmMxZTdhMzYyYTk5Yzc1MDIzOWFlYzZkOGYwZDJhMTI4ODgxMjBlZQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU"
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:5,
        https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/0.m4s?skid=default&signature=NjYzNDQ1MjBfYmRhZjgwZTk4NWQ3MWQ4NzI2ZWYzYzlhNTk4ZGFjMjFmMzVhMzRjYjYyZWM3MTM4NGY5MmQ5YWM2OGM2ZWVhNQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:5,
        https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/1.m4s?skid=default&signature=NjYzNDQ1MjBfNWFlMTAxZDUxNjM4ZDM3NGUwMzVjYmFiMGU3MTdhNjZmNDczNmVmZmUwMThjNTk1MzdlZDlhMDU5M2QzMjQyOA==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:5,
        https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/01kMRdxK00qua8np01BRijB5Mzj3YAtOo6by3wlOOZd008Fq01Z00m9FD9DggdgDROzLSgGhAeTF8fP5f6qySJz6gbhRnP7j7c4p02W02g01qYD2zmSg/2.m4s?skid=default&signature=NjYzNDQ1MjBfOGFjNTMyNzMzZDBlNjZmODRhZjFlMTdmY2E1NzRjOGM0ZWM0MGVhYmVlNGQxOWZhYmIwMjVjMzAxYmUzZjBiZA==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:5,
        https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/hpwcj01a1UaRF68TgfPme4LloXplUiXyTT01jYfBSc00ELcM01cAPF7D00XumM9HCRLxE49vFV2101XmXnh3Akvlwm9JRC6hx01544OMXmCXK027bxM/3.m4s?skid=default&signature=NjYzNDQ1MjBfODg0NGM3MzcyZGExMGNlOTJhMjgzOTc4ZGE1MDViNjFjNDhiZmFmYWIzODBlMGZlNzljNWQ3M2Y4YTYxOWY3NQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:3.85717,
        https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/W3YvyLLFCFvvjXQB2JgO3ApQfPFeWxDN4EZ01zuuRlieVPE9DF87YQ1CMD3zgvUoDayp7Vy4zK02CDxq2jmThORH0290002V588oQcHO02ld9PR2g/4.m4s?skid=default&signature=NjYzNDQ1MjBfZDQ5YzNmYTBiOTU0Yzc2MWI4NDhlMjBhZjY4MWM1NmE2ZDM4NTE4ZDM4YmY5YzllZWI4NDI0MmE1MmViM2E0Yg==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXT-X-ENDLIST
        """

        let expectedMappedRenditionPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:7
        #EXT-X-TARGETDURATION:5
        #EXT-X-MAP:URI="http://127.0.0.1:1234/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/18446744073709551615.m4s?skid=default&signature=NjYzNDQ1MjBfY2NiNDg1YWE0M2RiOTg5Nzc1NDJmYWVhZmMxZTdhMzYyYTk5Yzc1MDIzOWFlYzZkOGYwZDJhMTI4ODgxMjBlZQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU&__hls_origin_url=https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/18446744073709551615.m4s?skid=default&signature=NjYzNDQ1MjBfY2NiNDg1YWE0M2RiOTg5Nzc1NDJmYWVhZmMxZTdhMzYyYTk5Yzc1MDIzOWFlYzZkOGYwZDJhMTI4ODgxMjBlZQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU"
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/0.m4s?skid=default&signature=NjYzNDQ1MjBfYmRhZjgwZTk4NWQ3MWQ4NzI2ZWYzYzlhNTk4ZGFjMjFmMzVhMzRjYjYyZWM3MTM4NGY5MmQ5YWM2OGM2ZWVhNQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU&__hls_origin_url=https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/0.m4s?skid=default&signature=NjYzNDQ1MjBfYmRhZjgwZTk4NWQ3MWQ4NzI2ZWYzYzlhNTk4ZGFjMjFmMzVhMzRjYjYyZWM3MTM4NGY5MmQ5YWM2OGM2ZWVhNQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/1.m4s?skid=default&signature=NjYzNDQ1MjBfNWFlMTAxZDUxNjM4ZDM3NGUwMzVjYmFiMGU3MTdhNjZmNDczNmVmZmUwMThjNTk1MzdlZDlhMDU5M2QzMjQyOA==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU&__hls_origin_url=https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/YmJ02e0202vINrpopc1z02GsyMjYGi7mb8fcTrCuzbf0100fV2qGB7QTYe00LZYS1lv5SfZnmZtld1f9vDe4Px33t7Z00PWEEIhraxdItMuBz9jtaww/1.m4s?skid=default&signature=NjYzNDQ1MjBfNWFlMTAxZDUxNjM4ZDM3NGUwMzVjYmFiMGU3MTdhNjZmNDczNmVmZmUwMThjNTk1MzdlZDlhMDU5M2QzMjQyOA==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/01kMRdxK00qua8np01BRijB5Mzj3YAtOo6by3wlOOZd008Fq01Z00m9FD9DggdgDROzLSgGhAeTF8fP5f6qySJz6gbhRnP7j7c4p02W02g01qYD2zmSg/2.m4s?skid=default&signature=NjYzNDQ1MjBfOGFjNTMyNzMzZDBlNjZmODRhZjFlMTdmY2E1NzRjOGM0ZWM0MGVhYmVlNGQxOWZhYmIwMjVjMzAxYmUzZjBiZA==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU&__hls_origin_url=https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/01kMRdxK00qua8np01BRijB5Mzj3YAtOo6by3wlOOZd008Fq01Z00m9FD9DggdgDROzLSgGhAeTF8fP5f6qySJz6gbhRnP7j7c4p02W02g01qYD2zmSg/2.m4s?skid=default&signature=NjYzNDQ1MjBfOGFjNTMyNzMzZDBlNjZmODRhZjFlMTdmY2E1NzRjOGM0ZWM0MGVhYmVlNGQxOWZhYmIwMjVjMzAxYmUzZjBiZA==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/hpwcj01a1UaRF68TgfPme4LloXplUiXyTT01jYfBSc00ELcM01cAPF7D00XumM9HCRLxE49vFV2101XmXnh3Akvlwm9JRC6hx01544OMXmCXK027bxM/3.m4s?skid=default&signature=NjYzNDQ1MjBfODg0NGM3MzcyZGExMGNlOTJhMjgzOTc4ZGE1MDViNjFjNDhiZmFmYWIzODBlMGZlNzljNWQ3M2Y4YTYxOWY3NQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU&__hls_origin_url=https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/hpwcj01a1UaRF68TgfPme4LloXplUiXyTT01jYfBSc00ELcM01cAPF7D00XumM9HCRLxE49vFV2101XmXnh3Akvlwm9JRC6hx01544OMXmCXK027bxM/3.m4s?skid=default&signature=NjYzNDQ1MjBfODg0NGM3MzcyZGExMGNlOTJhMjgzOTc4ZGE1MDViNjFjNDhiZmFmYWIzODBlMGZlNzljNWQ3M2Y4YTYxOWY3NQ==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXTINF:3.85717,
        http://127.0.0.1:1234/v1/chunk/W3YvyLLFCFvvjXQB2JgO3ApQfPFeWxDN4EZ01zuuRlieVPE9DF87YQ1CMD3zgvUoDayp7Vy4zK02CDxq2jmThORH0290002V588oQcHO02ld9PR2g/4.m4s?skid=default&signature=NjYzNDQ1MjBfZDQ5YzNmYTBiOTU0Yzc2MWI4NDhlMjBhZjY4MWM1NmE2ZDM4NTE4ZDM4YmY5YzllZWI4NDI0MmE1MmViM2E0Yg==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU&__hls_origin_url=https://chunk-gcp-us-east4-vop1.fastly.mux.com/v1/chunk/W3YvyLLFCFvvjXQB2JgO3ApQfPFeWxDN4EZ01zuuRlieVPE9DF87YQ1CMD3zgvUoDayp7Vy4zK02CDxq2jmThORH0290002V588oQcHO02ld9PR2g/4.m4s?skid=default&signature=NjYzNDQ1MjBfZDQ5YzNmYTBiOTU0Yzc2MWI4NDhlMjBhZjY4MWM1NmE2ZDM4NTE4ZDM4YmY5YzllZWI4NDI0MmE1MmViM2E0Yg==&zone=0&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU
        #EXT-X-ENDLIST
        """

        let mapper = ReverseProxyServer.PlaylistLocalURLMapper()

        let encodedOriginalPlaylist = try XCTUnwrap(
            originalRenditionPlaylist.data(
                using: .utf8
            ),
            "Couldn't encode original rendition playlist"
        )

        let playlistOriginURL = try XCTUnwrap(
            URL(string: "https://manifest-gcp-us-east4-vop1.cfcdn.mux.com/W3YvyLLFCFvvjXQB2JgO3ApQfPFeWxDN4EZ01zuuRlieVPE9DF87YQ1CMD3zgvUoDayp7Vy4zK02CDxq2jmThORH0290002V588oQcHO02ld9PR2g/rendition.m3u8?cdn=fastly&expires=1714701600&skid=default&signature=NjYzNDQ1MjBfOTJlMmY5NDUyOTE4ZDFjNmI1OTQ4ZWU3YzljZjllMTZkM2M0YmE5ZmFkMTk5ZmQ4OWVhNTZhNmQ5ODg0NGYzNw==&vsid=PzF8MS201Rjz6a6n01701kdrzsmUj1MTbYeBiaeCzAFui2yAbv01FD9DzN02gBmtd4GeiAt8wRRWBjgU"),
            "Couldn't create manifest origin URL"
        )

        let encodedMappedRenditionPlaylist = try XCTUnwrap(
            mapper.processEncodedPlaylist(
                encodedOriginalPlaylist,
                playlistOriginURL: playlistOriginURL
            ),
            "Couldn't map to local URLs in rendition playlist"
        )

        let mappedRenditionPlaylist = try XCTUnwrap(
            String(
                data: encodedMappedRenditionPlaylist,
                encoding: .utf8
            )?.removingPercentEncoding,
            "Couldn't decode rendition playlist"
        )

        XCTAssertEqual(
            mappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines).count,
            expectedMappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines).count
        )

        for index in 0..<mappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines).count {
            XCTAssertEqual(
                mappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines)[index],
                expectedMappedRenditionPlaylist.components(separatedBy: CharacterSet.newlines)[index]
            )
        }

        XCTAssertEqual(
            mappedRenditionPlaylist,
            expectedMappedRenditionPlaylist
        )
    }
}
