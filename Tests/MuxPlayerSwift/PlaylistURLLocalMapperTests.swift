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

        let mappedMultivariantPlaylist = String(
            data: encodedMappedMultivariantPlaylist,
            encoding: .utf8
        )

        XCTAssertEqual(
            mappedMultivariantPlaylist,
            expectedMappedMultivarantPlaylist
        )
    }

    func testRenditionPlaylistPlaylistLocalURLMapping() throws {
        let originalRenditionPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:6
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/OvBswJ01THCr9vVhhgKhWYo9FRKmPaVQPY1Cqc73ShNTX4XeNe01tCCk5hFCbXdyN3DEMtkXkkUKU02L502Vpnp17Q/0.ts?skid=default&signature=NjVjZWViZDBfYmNmMmExMTNiOTZjMzZjMDNmY2M1ODNlNDIyZDJjMzU2ODM1MjY4ODRmZmZjY2JkZmEwZDUxN2MzYjliYTY4Ng==&zone=1
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/OvBswJ01THCr9vVhhgKhWYo9FRKmPaVQPY1Cqc73ShNTX4XeNe01tCCk5hFCbXdyN3DEMtkXkkUKU02L502Vpnp17Q/1.ts?skid=default&signature=NjVjZWViZDBfMjNhYTM2M2Y3ZWUxM2NmNTk5MDgxYzc3YjZmMTljODQ5MTllYzc0ZWY4ODAyMGMxY2E5NmUzZWRkM2U3NWM3Yw==&zone=1
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/SvqDW01AkSp3ZzD01rlejLGZAO52Ke4J1DWI02C00Kz4MfzreU00shhPgxSd7U5n9LGJBz7YJTH2EJbuXrJU2RJdm1w/2.ts?skid=default&signature=NjVjZWViZDBfMzA1ODExODZlMTM4MjFiNTEwNjQ3ZGFhMmNhZTNmYTY4MmI0ODc0OTBiMzg0YjM4MTg0MjJjODM0MDc2YTE0ZA==&zone=1
        #EXTINF:5,
        https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/00F02RgxOeCOsfBQAy94c02kmytrY8hsu00yP1IjkR8knFX641jM6DJVuXIm2fPcR1pEJfl83z3H008SqfYXOupD8Rg/3.ts?skid=default&signature=NjVjZWViZDBfODY2MGRiMjBjY2JmNzU0N2Q4YjVkYWU2Yzg2YmQxM2RkYTlkMDMwMzg1NGUzODUwNDJlMDc2Yjg4ZjdkM2Y5Yg==&zone=1
        #EXTINF:3.85717,
        https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/qyHnst9BVpSF4nZpMK8AcilKpgoNrCgNjEPLuepuB5rNKh008j8zOxI00VMlBMfKo7QFnBpHhQ6I8/4.ts?skid=default&signature=NjVjZWViZDBfMDY5N2FjZTU2MTczYmM4NGE3NTM4NWQ1ZGRiMmVhNWY5NmNkMGM0NGZhOTc4YWFjOGQwZDE0NmE0MTJhMGU0OA==&zone=1
        #EXT-X-ENDLIST
        """

        let expectedMappedRenditionPlaylist = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:6
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/OvBswJ01THCr9vVhhgKhWYo9FRKmPaVQPY1Cqc73ShNTX4XeNe01tCCk5hFCbXdyN3DEMtkXkkUKU02L502Vpnp17Q/0.ts?skid=default&signature=NjVjZWViZDBfYmNmMmExMTNiOTZjMzZjMDNmY2M1ODNlNDIyZDJjMzU2ODM1MjY4ODRmZmZjY2JkZmEwZDUxN2MzYjliYTY4Ng%3D%3D&zone=1&__hls_origin_url=https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/OvBswJ01THCr9vVhhgKhWYo9FRKmPaVQPY1Cqc73ShNTX4XeNe01tCCk5hFCbXdyN3DEMtkXkkUKU02L502Vpnp17Q/0.ts?skid%3Ddefault%26signature%3DNjVjZWViZDBfYmNmMmExMTNiOTZjMzZjMDNmY2M1ODNlNDIyZDJjMzU2ODM1MjY4ODRmZmZjY2JkZmEwZDUxN2MzYjliYTY4Ng%3D%3D%26zone%3D1
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/OvBswJ01THCr9vVhhgKhWYo9FRKmPaVQPY1Cqc73ShNTX4XeNe01tCCk5hFCbXdyN3DEMtkXkkUKU02L502Vpnp17Q/1.ts?skid=default&signature=NjVjZWViZDBfMjNhYTM2M2Y3ZWUxM2NmNTk5MDgxYzc3YjZmMTljODQ5MTllYzc0ZWY4ODAyMGMxY2E5NmUzZWRkM2U3NWM3Yw%3D%3D&zone=1&__hls_origin_url=https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/OvBswJ01THCr9vVhhgKhWYo9FRKmPaVQPY1Cqc73ShNTX4XeNe01tCCk5hFCbXdyN3DEMtkXkkUKU02L502Vpnp17Q/1.ts?skid%3Ddefault%26signature%3DNjVjZWViZDBfMjNhYTM2M2Y3ZWUxM2NmNTk5MDgxYzc3YjZmMTljODQ5MTllYzc0ZWY4ODAyMGMxY2E5NmUzZWRkM2U3NWM3Yw%3D%3D%26zone%3D1
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/SvqDW01AkSp3ZzD01rlejLGZAO52Ke4J1DWI02C00Kz4MfzreU00shhPgxSd7U5n9LGJBz7YJTH2EJbuXrJU2RJdm1w/2.ts?skid=default&signature=NjVjZWViZDBfMzA1ODExODZlMTM4MjFiNTEwNjQ3ZGFhMmNhZTNmYTY4MmI0ODc0OTBiMzg0YjM4MTg0MjJjODM0MDc2YTE0ZA%3D%3D&zone=1&__hls_origin_url=https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/SvqDW01AkSp3ZzD01rlejLGZAO52Ke4J1DWI02C00Kz4MfzreU00shhPgxSd7U5n9LGJBz7YJTH2EJbuXrJU2RJdm1w/2.ts?skid%3Ddefault%26signature%3DNjVjZWViZDBfMzA1ODExODZlMTM4MjFiNTEwNjQ3ZGFhMmNhZTNmYTY4MmI0ODc0OTBiMzg0YjM4MTg0MjJjODM0MDc2YTE0ZA%3D%3D%26zone%3D1
        #EXTINF:5,
        http://127.0.0.1:1234/v1/chunk/00F02RgxOeCOsfBQAy94c02kmytrY8hsu00yP1IjkR8knFX641jM6DJVuXIm2fPcR1pEJfl83z3H008SqfYXOupD8Rg/3.ts?skid=default&signature=NjVjZWViZDBfODY2MGRiMjBjY2JmNzU0N2Q4YjVkYWU2Yzg2YmQxM2RkYTlkMDMwMzg1NGUzODUwNDJlMDc2Yjg4ZjdkM2Y5Yg%3D%3D&zone=1&__hls_origin_url=https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/00F02RgxOeCOsfBQAy94c02kmytrY8hsu00yP1IjkR8knFX641jM6DJVuXIm2fPcR1pEJfl83z3H008SqfYXOupD8Rg/3.ts?skid%3Ddefault%26signature%3DNjVjZWViZDBfODY2MGRiMjBjY2JmNzU0N2Q4YjVkYWU2Yzg2YmQxM2RkYTlkMDMwMzg1NGUzODUwNDJlMDc2Yjg4ZjdkM2Y5Yg%3D%3D%26zone%3D1
        #EXTINF:3.85717,
        http://127.0.0.1:1234/v1/chunk/qyHnst9BVpSF4nZpMK8AcilKpgoNrCgNjEPLuepuB5rNKh008j8zOxI00VMlBMfKo7QFnBpHhQ6I8/4.ts?skid=default&signature=NjVjZWViZDBfMDY5N2FjZTU2MTczYmM4NGE3NTM4NWQ1ZGRiMmVhNWY5NmNkMGM0NGZhOTc4YWFjOGQwZDE0NmE0MTJhMGU0OA%3D%3D&zone=1&__hls_origin_url=https://chunk-gcp-us-east1-vop1.fastly.mux.com/v1/chunk/qyHnst9BVpSF4nZpMK8AcilKpgoNrCgNjEPLuepuB5rNKh008j8zOxI00VMlBMfKo7QFnBpHhQ6I8/4.ts?skid%3Ddefault%26signature%3DNjVjZWViZDBfMDY5N2FjZTU2MTczYmM4NGE3NTM4NWQ1ZGRiMmVhNWY5NmNkMGM0NGZhOTc4YWFjOGQwZDE0NmE0MTJhMGU0OA%3D%3D%26zone%3D1
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
            URL(string: "https://manifest-gcp-us-east1-vop1.fastly.mux.com/qyHnst9BVpSF4nZpMK8AcilKpgoNrCgNjEPLuepuB5rNKh008j8zOxI00VMlBMfKo7QFnBpHhQ6I8/rendition.m3u8?cdn=fastly&expires=1708059600&skid=default&signature=NjVjZWViZDBfMWNlMjdjZDFlNTg1MGVlNjJmMjVmNDFkMjY0ZTY0M2I2YWJhYzQ0ZjRhMTNlYjQ2YmNiMDMyZjYzNTFmMDI2Ng==&vsid=UxwWoZ023025LmoJn1vaJvtoDTLKPhmpL35e5wQtduTwfFSQyqcThzqR3Tw3fD7Jaq02Uc01nbIQBZg"),
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
            ),
            "Couldn't decode rendition playlist"
        )

        XCTAssertEqual(
            mappedRenditionPlaylist,
            expectedMappedRenditionPlaylist
        )
    }
}
