//
//  AVPlayerItem+Mux.swift
//

import AVFoundation
import Foundation

internal enum PlaybackURLConstants {
    static let reverseProxyScheme = "http"

    static let reverseProxyHost = "127.0.0.1"

    static let reverseProxyPort = Int(1234)
}

// TODO: this extension has been modified. It has been hackily refactored to fit our proof-of-concept
public extension AVPlayerItem {

    // Initializes a player item with a playback URL that
    // references your Mux Video at the supplied playback ID.
    // The playback ID must be public.
    //
    // This initializer uses https://stream.mux.com as the
    // base URL. Use a different initializer if using a custom
    // playback URL.
    //
    // - Parameter playbackID: playback ID of the Mux Asset
    // you'd like to play
    convenience init(playbackID: String) {
        guard let playbackURL = URLComponents(
           playbackID: playbackID,
           playbackOptions: PlaybackOptions()
       ).url else {
           preconditionFailure("Invalid playback URL components")
       }
        
        self.init(
            playbackURL: playbackURL,
            playbackID: playbackID,
            playbackOptions: PlaybackOptions(),
            playerSDK: .shared
        )
    }

    // Initializes a player item with a playback URL that
    // references your Mux Video at the supplied playback ID.
    // The playback ID must be public.
    //
    // - Parameters:
    //   - playbackID: playback ID of the Mux Asset
    //   you'd like to play
    convenience init(
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
         guard let playbackURL = URLComponents(
            playbackID: playbackID,
            playbackOptions: playbackOptions
        ).url else {
            preconditionFailure("Invalid playback URL components")
        }

        self.init(
            playbackURL: playbackURL,
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            playerSDK: .shared
        )
    }
    
    //TODO: we only have this URL-based initializer for the PoC. The real version would know which mux domain to hit, but this version is just hitting a test server
    convenience init(
        url: URL,
        playbackID: String,
        playbackOptions: PlaybackOptions
    ) {
        self.init(
            playbackURL: url,
            playbackID: playbackID,
            playbackOptions: playbackOptions,
            playerSDK: .shared
        )
    }
    
    internal convenience init(
        playbackURL: URL,
        playbackID: String,
        playbackOptions: PlaybackOptions,
        playerSDK: PlayerSDK
    ) {
        // Create a new `AVAsset` that has been prepared
        // for playback
       
        let asset = AVURLAsset(
            url: playbackURL
        )
        
        PlayerSDK.shared.diagnosticsLogger.info("setting delegate for AVURLAsset pointing to \(playbackURL.absoluteString)")
        asset.resourceLoader.setDelegate(
            PlayerSDK.shared.resourceLoaderDelegate,
            queue: PlayerSDK.shared.resourceLoaderDispatchQueue
        )
        
        self.init(
            asset: asset
        )
        
        // Added for the proof-of-concept. The default is a lot more than this, like half the video. If we want shortform to be cheap for customers, we don't want to prewarm 300sec of video
        self.preferredForwardBufferDuration = 10.0
        
        playerSDK.registerPlayerItem(
            self,
            playbackID: playbackID,
            playbackOptions: playbackOptions
        )
    }
}

public extension AVPlayerItem {

    // Extracts Mux playback ID from remote AVAsset, if possible
    var playbackID: String? {
        guard let remoteAsset = asset as? AVURLAsset else {
            return nil
        }

        guard let components = URLComponents(
            url: remoteAsset.url,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        guard let host = components.host, host.contains("stream.") else {
            return nil
        }

        guard components.path.hasSuffix(".m3u8") else {
            return nil
        }

        var path = components.path

        path.removeLast(5)

        path.removeFirst(1)

        return path
    }
}

/// AVAssetResourceLoaderDelegate for loading Mux's short-form HLS media playlists
/// Requests a well-formatted init segment and generates a media playlist based on what it got back
/// ``PlayerSDK`` retains a single instance of this Delegate, to be used by all AVURLAssets loading short-form playlists
internal class ShortFormAssetLoaderDelegate : NSObject, AVAssetResourceLoaderDelegate {
    
    // TODO: In the real thing, we'll need to support multiple Tasks at the same time since you can have multiple items. Accomplish this either by having multiple delegates (hard because we don't really have an object with a predictable lifecycle that can own them except indefinitely) or by having multiple Tasks and init segments cached someplace (might still be hard because we still don't have anything with a known lifecycle that we control that can own *those*)
    private var fetchTask: Task<Void, any Error>? = nil
    
    // TODO: same as in the ReverseProxyServer, but maybe we should have PlayerSDK provide a URLSession to both
    let urlSession: URLSession = URLSession.shared
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        PlayerSDK.shared.diagnosticsLogger.debug("shouldWaitForLoadingOfRequestedResource: called")
        PlayerSDK.shared.diagnosticsLogger.debug("shouldWaitForLoadingOfRequestedResource: url is \(loadingRequest.request.url!)")
        
        if let url = loadingRequest.request.url,
            isURLForShortform(url: url) {
            PlayerSDK.shared.diagnosticsLogger.debug("WAS short-form URL")
            // We are definitely not in an SC context here, just explicity make a new context
            fetchTask = Task.detached { [self] in
                // TODO: Proof-of-concept just always uses the proxy cache. Disabling caching feels silly but maybe customers really don't want to use the 256M
                await MainActor.run { PlayerSDK.shared.reverseProxyServer.start() }
                
                do {
                    try await answerRequestForMediaPlaylist(
                        resourceLoadingRequest: loadingRequest,
                        playlistURL: url,
                        originBaseURL: makeOriginBaseURL(playlistURL: url),
                        cacheBaseURL: URL(string: "https://mux.com")! // TODO: Didn't need this param
                    )
                } catch {
                    PlayerSDK.shared.diagnosticsLogger.error(
                        "Error fetching/generating short-form playlist: \(error.localizedDescription)"
                    )
                    loadingRequest.finishLoading(with: error)
                }
                fetchTask = nil
            }
            
            return true
        } else {
            return false
        }
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        // As long as the methods of this delegate are called without interleaving (i think they are), this should be fine
        fetchTask?.cancel()
    }
    
    private func answerRequestForMediaPlaylist(
        resourceLoadingRequest loadingRequest: AVAssetResourceLoadingRequest,
        playlistURL: URL,
        originBaseURL: URL,
        cacheBaseURL: URL
    ) async throws {
        // TODO: The most straightforward way to cache the init segment is via the same proxy cache as everything else, but this *does* mean we might evict an init segment and have to re-request it even in the same app session (which is probably not necessary)
        //        let initSegmentURL = makeInitSegmentURL(playlistURL: playlistURL)
        let initSegmentURL = makeCacheProxyURL(forFullURL: makeInitSegmentURL(playlistURL: playlistURL))
        
        PlayerSDK.shared.diagnosticsLogger.info(
            "[shorform-test] initSegmentURL: \(initSegmentURL.absoluteString)"
        )

        let segmentData = try await fetchInitSegment(initSegmentURL: initSegmentURL)
        PlayerSDK.shared.diagnosticsLogger.debug("resourceLoader fetched \(segmentData.count) bytes")
        
        // TODO: The target duration (and real segment duration; can be different) should maybe come down from the server via Response Header, if that's the way the origin is going to give us information
        // TODO: (continued) .. although for playback, we might not need the real target duration...
        let playlistString = try ShortFormMediaPlaylistGenerator(
            initSegment: segmentData,
            originBaseURL: originBaseURL,
            cacheProxyBaseURL: cacheBaseURL,
            playlistAttributes: ShortFormMediaPlaylistGenerator.PlaylistAttributes(
                version: 7,
//                        targetDuration: 5, // TODO: wouldn't a mux video asset have 6?
//                        extinfSegmentDuration: 5 // TODO: wouldn't a mux video asset have 5?
                targetDuration: 4, // TODO: wouldn't a mux video asset have 6?
                extinfSegmentDuration: 4.16667 // TODO: wouldn't a mux video asset have 5?
            )
        ).playlistString()
        
        
        PlayerSDK.shared.diagnosticsLogger.debug("generated playlist:\n\(playlistString)")

        let playlistData = playlistString.data(using: .utf8)
        guard let playlistData else {
            throw ShortFormRequestError.unexpected(url: playlistURL, message: "playlist didn't encode to utf-8")
        }
        
        let requestedStart = loadingRequest.dataRequest?.requestedOffset
        let requestedLength = loadingRequest.dataRequest?.requestedLength
        
        loadingRequest.contentInformationRequest?.contentType = "application/vnd.apple.mpegurl"
        loadingRequest.contentInformationRequest?.contentLength = Int64(playlistData.count)
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
        
        loadingRequest.dataRequest!.respond(with: playlistData)
        loadingRequest.finishLoading()
    }
    
    /// returns (requestedOffset, requestedLength) if the request was for a byte range of the
    private func byteRange(loadingRequest: AVAssetResourceLoadingRequest) -> (Int64, Int)? {
        guard
            let dataRequest = loadingRequest.dataRequest, !dataRequest.requestsAllDataToEndOfResource
        else { return nil }
            
        return (
            dataRequest.requestedOffset,
            dataRequest.requestedLength
        )
    }
    
    private func isURLForShortform(url: URL) -> Bool {
        // TODO: 'shortform.mux.com/[playbackID].m3u8' or something like that
        // expected path (for the proof-of-concept) "short-form-tests/v1/playbackID/media.m3u8"
        let isShortForm = url.pathComponents.contains { $0 == "short-form-tests" }
            && url.lastPathComponent == "media.m3u8"
        return isShortForm
    }
    
    private func makeInitSegmentURL(playlistURL: URL) -> URL {
        return URL(string:"\(makeOriginBaseURL(playlistURL: playlistURL))/init.mp4")!
    }
    

    
    private func makeOriginBaseURL(playlistURL: URL) -> URL {
        // current path: some-host/short-form-tests/v1/[playbackID]/media.m3u8
        let playbackID = playlistURL.pathComponents[3]
        let host = playlistURL.host
        let port = playlistURL.port
        
        var urlComponents = URLComponents()
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = "/short-form-tests/v1/\(playbackID)"
        urlComponents.scheme = "http"
        
        return urlComponents.url! // TODO: yknow, maybe handle
    }
    
    private func fetchInitSegment(initSegmentURL url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse // TODO: unchecked cast safe in practice but eep
        
        PlayerSDK.shared.diagnosticsLogger.debug("fetchInitSegment: response code \(httpResponse.statusCode)")
        
        if (httpResponse.statusCode != 200) {
            throw ShortFormRequestError.httpStatus(url: url, responseCode: httpResponse.statusCode)
        }
        
        return data
    }
}

internal class ShortFormMediaPlaylistGenerator {
    static let movieHeaderType: Data = "mvhd".data(using: .ascii)! // not risky
    // relative to the start of the box
    static let movieHeaderTimeScaleOffset: Int = 20
    // relative to the start of the box
    static let movieHeaderDurationOffset: Int = 24

    let initSegmentData: Data
    let playlistAttributes: PlaylistAttributes
    let originBase: URLComponents
    let cacheProxyBase: URLComponents
    
    func playlistString() throws -> String {
        let originBaseURLStr = originBase.string!
        
        let initSegmentProxiedURL = makeCacheProxyURL(
            forFullURL: URL(string: "\(originBaseURLStr)/init.mp4")!
        )
        
        let preambleLines = [
            Tags.extM3U(),
            Tags.version(7),
            Tags.targetDuration(playlistAttributes.targetDuration),
            Tags.mediaSequence(startingFromSequenceNumber: 0),
//            Tags.map(uri: "\(originBaseURLStr)/init.mp4", range: nil),
            Tags.map(uri: initSegmentProxiedURL.absoluteString, range: nil),
            Tags.discontunityMarker()
        ]
        
        // TODO: Might want to check the trak's too, and take the longest duration(?)
        // TODO: The final impl of this may depend on a source of duration other than spec-deviant init segments
        let mvhdDuration = try findMVHDDurationSec(mp4Data: initSegmentData)
        
        let segmentDuration = playlistAttributes.extinfSegmentDuration
            ?? Double(playlistAttributes.targetDuration)
        let segmentsPerStream = mvhdDuration / segmentDuration
        let numberOfSegments = ceil(segmentsPerStream) // including the last segment
        let wholeSegments = floor(segmentsPerStream)
        let lastSegmentDuration = (numberOfSegments - wholeSegments) * segmentDuration
        
        var segmentLines: [String] = []
        for segmentNumber in 0..<Int(wholeSegments) {
            let segmentURL = "\(originBaseURLStr)/\(segmentNumber).mp4"
            let proxiedSegmentURL = makeCacheProxyURL(forFullURL: URL(string:segmentURL)!)
            
            segmentLines.append(Tags.extinf(segmentDuration: segmentDuration, title: nil))
//            segmentLines.append(segmentURL)
            segmentLines.append(proxiedSegmentURL.absoluteString)
            
        }
        
        // If the last segment is less than 10msec, we dont need to worry about it
        if !approximatelyEqual(lastSegmentDuration, 0, tolerance: 0.01) {
            let proxiedLastSegmentURL = makeCacheProxyURL(
                forFullURL: URL(string: "\(originBaseURLStr)/\(Int(numberOfSegments - 1)).mp4")!
            )
            
            segmentLines.append(Tags.extinf(segmentDuration: lastSegmentDuration, title: nil))
            //            segmentLines.append("\(originBaseURLStr)/\(Int(numberOfSegments - 1)).mp4")
            segmentLines.append(proxiedLastSegmentURL.absoluteString)
        }
        
        let endingLines = [
            Tags.endlist()
        ]
        
        return (preambleLines + segmentLines + endingLines).joined(separator: "\n")
    }
    
    private func findMVHDDurationSec(mp4Data: Data) throws -> TimeInterval {
        let mvhdTypeRange = mp4Data.range(of: ShortFormMediaPlaylistGenerator.movieHeaderType)
        guard let mvhdTypeRange, !mvhdTypeRange.isEmpty else {
            throw ShortFormRequestError.unexpected(message: "no mvhd found in int segment")
        }
        
        let boxStart = mvhdTypeRange.startIndex - 4 // 4 bytes for the size field
        guard boxStart >= 0 else {
            throw ShortFormRequestError.unexpected(message: "mvhd start was out of bounds")
        }
        let boxSize = try readInt32(data: mp4Data, at: UInt(boxStart))
        let boxEnd = Int32(boxStart) + boxSize // not inclusive
        guard boxEnd <= mp4Data.count else {
            throw ShortFormRequestError.unexpected(message: "mvhd end was out of bounds")
        }
        
        let timescaleStart = boxStart + ShortFormMediaPlaylistGenerator.movieHeaderTimeScaleOffset
        let durationStart = boxStart + ShortFormMediaPlaylistGenerator.movieHeaderDurationOffset
        let timescale = try readInt32(data: mp4Data, at: UInt(timescaleStart))
        let duration = try readInt32(data: mp4Data, at: UInt(durationStart))
        
        return Double(duration) / Double(timescale)
    }
    
    private func approximatelyEqual(_ lhs: Double, _ rhs: Double, tolerance: Double) -> Bool {
        return abs(lhs - rhs) <= tolerance
    }
    
    /// Reads an int32 out of the given data. The data is read big-endian because isobmff files are big-endian
    private func readInt32(data: Data, at offset: UInt) throws -> Int32 {
        guard data.count >= 4 && offset < data.count - 4 else {
            throw ShortFormRequestError.unexpected(message: "readInt32: out of bounds")
        }
        return data[offset..<(offset + 4)].withUnsafeBytes { bytePointer in
            return bytePointer.load(as: Int32.self).bigEndian
        }
    }
    
    /// @param originBaseURL: An aboslute URL that points to the path where segments can be found (ie, `https://shortform.mux.com/abc23/`
    /// @param cacheProxyURL: An absolute URL that points to the path where the cache proxy is (ie, `http://127.0.0.1:1234/`)
    init(
        initSegment: Data,
        originBaseURL: URL,
        cacheProxyBaseURL: URL,
        playlistAttributes: PlaylistAttributes
    ) {
        self.initSegmentData = initSegment
        self.playlistAttributes = playlistAttributes
        
        // since we are not resolvingAgainstBaseURL, there's no risk of these initializers returning nil
        self.cacheProxyBase = URLComponents(url: cacheProxyBaseURL, resolvingAgainstBaseURL: false)!
        self.originBase = URLComponents(url: originBaseURL, resolvingAgainstBaseURL: false)!
    }
    
    struct PlaylistAttributes {
        let version: UInt
        let targetDuration: UInt
        let extinfSegmentDuration: Double? // assumed to be the target duration if not specified
    }
    
    private class Tags {
        static func extM3U() -> String {
            return "#EXTM3U"
        }
        static func discontunityMarker() -> String {
            return "#EXT-X-DISCONTINUITY"
        }
        static func version(_ version: UInt) -> String {
            return "#EXT-X-VERSION:\(version)"
        }
        static func targetDuration(_ duration: UInt) -> String {
            return "#EXT-X-TARGETDURATION:\(duration)"
        }
        static func mediaSequence(startingFromSequenceNumber sn: UInt) -> String {
            return "#EXT-X-MEDIA-SEQUENCE:\(sn)"
        }
        static func map(uri: String, range: (UInt, UInt?)?) -> String {
            let base = "#EXT-X-MAP:URI=\"\(uri)\""
            if let (start, offset) = range {
                if let offset {
                    return "\(base),BYTERANGE=\"\(start)@\(offset)\""
                } else {
                    return "\(base),BYTERANGE=\"\(start)\""
                }
            } else {
                return base
            }
        }
        static func extinf(segmentDuration: Double, title: String?) -> String {
            let base = "#EXTINF:\(String(describing: segmentDuration))"
            if let title {
                return "\(base),\(title)"
            } else {
                return base
            }
        }
        static func endlist() -> String {
            return "#EXT-X-ENDLIST"
        }
    }
}

internal enum ShortFormRequestError: Error {
    case because(url: URL, cause: any Error)
    case httpStatus(url: URL, responseCode: Int)
    case unexpected(url: URL?, message: String)
    case unexpected(message: String)
}

fileprivate func makeCacheProxyURL(forFullURL url: URL) -> URL {
    var components = URLComponents()
    components.scheme = PlaybackURLConstants.reverseProxyScheme
    components.host = PlaybackURLConstants.reverseProxyHost
    components.port = PlaybackURLConstants.reverseProxyPort
    
    components.path = url.path
    
    components.queryItems = [
        URLQueryItem(
            name: PlayerSDK.shared.reverseProxyServer.originURLKey,
            value: url.absoluteString
        )
    ]
    
    return components.url!
}
