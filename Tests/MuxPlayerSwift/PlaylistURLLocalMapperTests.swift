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

        let expectedMappedMultivarantPlaylist = """
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
