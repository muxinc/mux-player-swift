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
        
        // TODO: won't be called at all for http/https, also we'd need our own dispatch queue here, which is a pointless pain
        //  what we're doing instead is using the RPS to handle all the requests including the manifest
        PlayerSDK.shared.diagnosticsLogger.info("setting delegate for AVURLAsset pointing to \(playbackURL.absoluteString)")
        asset.resourceLoader.setDelegate(
            PlayerSDK.shared.resourceLoaderDelegate,
            queue: PlayerSDK.shared.resourceLoaderDispatchQueue
        )
        
//        asset.resourceLoader.setDelegate(
//            PlayerSDK.shared.loggingDelegate,
//            queue: PlayerSDK.shared.resourceLoaderDispatchQueue
//        )
        
        self.init(
            asset: asset
        )

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

internal class RequestLoggingAssetLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    
    // OKAY WHAT HAVE WE FOUND? You can't actually send segment data this way. AVPlayer just ignores it undocumented-ly
    //  We need to redirect to ReverseProxyServer (either in this request or by rewriting the manifest)
    // https://developer.apple.com/forums/thread/113063
    // https://stackoverflow.com/questions/39962882/video-streaming-fails-when-using-avassetresourceloader
    // (both from this blog: https://medium.com/@alinekborges/urlsession-tampering-with-avplayer-03bc8f41156c)
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        
        Task.detached { [self] in
            do {
                let incomingReq = loadingRequest.request
                let specialURL = incomingReq.url!
                print("LDELEGATE: Got request \(loadingRequest.request)")
                print("LDELEGATE: Got request for URL \(loadingRequest.request.url)")
                print("LDELEGATE: Data Request is \(loadingRequest.dataRequest)")
                print("LDELEGATE: Data Request for all bytes? \(loadingRequest.dataRequest?.requestsAllDataToEndOfResource)")
                print("LDELEGATE: Data Request for offset \(loadingRequest.dataRequest?.requestedOffset)")
                print("LDELEGATE: Data Request .. and legnth \(loadingRequest.dataRequest?.requestedLength)")

                let outboundURL = {
                    var comps = URLComponents(url: specialURL, resolvingAgainstBaseURL: false)!
                    comps.scheme = "http" // TODO: if this wasn't just a quick logging thing, try not losing the scheme
                    return comps.url!
                }()
                var actualRequest = URLRequest(url: outboundURL)
                actualRequest.httpMethod = incomingReq.httpMethod
                
                print("LDELEGATE: Actually requesting URL \(actualRequest.url)")
                
                let (data, response) = try await URLSession.shared.data(for: actualRequest)
                
                print("LDELEGATE: Response Code \((response as! HTTPURLResponse).statusCode)")
                print("LDELEGATE: Response Len \(response.expectedContentLength)")
                print("LDELEGATE: Response MIME \(response.mimeType)")
                print("LDELEGATE: Response data is \(data.count) bytes")
                
                
                // TODO: Works for init segment too??
                let responseType: String? = {
                    if response.mimeType == "video/mp4" {
                        return AVFileType.mp4.rawValue
                    } else {
                        return response.mimeType
                    }
                }()
                
                print("LDELEGATE: responding with type \(responseType)")
//                loadingRequest.contentInformationRequest?.contentType = response.mimeType
                loadingRequest.contentInformationRequest?.contentType = responseType!
                loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
//                loadingRequest.contentInformationRequest?.contentLength = response.expectedContentLength
                loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
                
                loadingRequest.dataRequest!.respond(with: data)
                loadingRequest.finishLoading()
            } catch {
                print("\nLDELEGATE: ERROR! \(error.localizedDescription)")
                loadingRequest.finishLoading(with: error)
            }
        }
        
        return true
    }
}

/// AVAssetResourceLoaderDelegate for loading Mux's short-form HLS media playlists
/// Requests a well-formatted init segment and generates a media playlist based on what it got back
/// ``PlayerSDK`` retains a single instance of this Delegate, to be used by all AVURLAssets loading short-form playlists
internal class ShortFormAssetLoaderDelegate : NSObject, AVAssetResourceLoaderDelegate {
    
    // TODO: same as in the ReverseProxyServer, but maybe we should have PlayerSDK provide a URLSession to both
    let urlSession: URLSession = URLSession.shared
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        PlayerSDK.shared.diagnosticsLogger.debug("shouldWaitForLoadingOfRequestedResource: called")
        PlayerSDK.shared.diagnosticsLogger.debug("shouldWaitForLoadingOfRequestedResource: url is \(loadingRequest.request.url!)")
        
        if let url = loadingRequest.request.url,
            isURLForShortform(url: url)
        {
            PlayerSDK.shared.diagnosticsLogger.debug("WAS short-form URL")
            
            let originBaseURL = makeOriginBaseURL(playlistURL: url)
            
            let initSegmentURL = makeInitSegmentURL(playlistURL: url)
            PlayerSDK.shared.diagnosticsLogger.info(
                "[shorform-test] initSegmentURL: \(initSegmentURL.absoluteString)"
            )
            
            // TODO: init segments should be cached somewhere (but must generate a playlist 1st)
            
            // check if init segment is cached already
            // Get init segment from wherever it's needed
            // cache init segment in the reverse proxy
            // generate playlist from init segment
            
            PlayerSDK.shared.diagnosticsLogger.debug("Creating new init-segment fetch")
            // TODO: need to track these someplace (a Map in this object maybe) so we can cancel them
            // Explicitly create a detached task (though Task {} would implicitly create a detached scope in this case)
            Task.detached { [self] in do {
                let segmentData = try await fetchInitSegment(initSegmentURL: initSegmentURL)
                PlayerSDK.shared.diagnosticsLogger.debug("resourceLoader fetched \(segmentData.count) bytes")
                
                let playlistString = try ShortFormMediaPlaylistGenerator(
                    initSegment: segmentData,
//                    originBaseURL: URL(string: "https://mux.com")!, // TODO: Real URL
                    originBaseURL: originBaseURL,
                    cacheProxyBaseURL: URL(string: "https://mux.com")!, // TODO: Real URL
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
                    throw ShortFormRequestError.unexpected(url: url, message: "playlist didn't encode to utf-8")
                }
                
                let requestedStart = loadingRequest.dataRequest?.requestedOffset
                let requestedLength = loadingRequest.dataRequest?.requestedLength
                
                loadingRequest.contentInformationRequest?.contentType = "application/vnd.apple.mpegurl"
                loadingRequest.contentInformationRequest?.contentLength = Int64(playlistData.count)
                loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
                
                loadingRequest.dataRequest!.respond(with: playlistData)
                // TODO: handle Errors by actually catching something :)
                loadingRequest.finishLoading()
            } catch {
                PlayerSDK.shared.diagnosticsLogger.error("Error caught while generating playlist")
            }}

            return true
        } else {
            return false
        }
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        // TODO: Cancel downloading
    }
    
//    func resourceLoader(
//        _ resourceLoader: AVAssetResourceLoader,
//        shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest
//    ) -> Bool {
//        // TODO: maybe try to download it again? I dunno
//        <#code#>
//    }
    
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
        // current path: some-host/short-form-tests/v1/[playbackID]/media.m3u8
        let playbackID = playlistURL.pathComponents[3]
        let host = playlistURL.host
        let port = playlistURL.port
        
        var urlComponents = URLComponents()
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = "/short-form-tests/v1/\(playbackID)/init.mp4"
        urlComponents.scheme = "http"
        
        return urlComponents.url! // TODO: yknow, maybe handle
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
        
        // init segments are really tiny and have no media data, so we don't need to stream them
        return data
    }
    
    // TODO: What we really need, is a SegmentFetcher actor with a cancel method that will
    //  cancel the URLSessionTask and also the SC Task that does this
    // TODO: I made the thing I claimed we need, but let's try it before we go forward
    private func fetchInitSegmentOldApis(initSegURL url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let request = URLRequest(url: url)
            
            let task = urlSession.dataTask(with: request) { data, response, err in
                if let err {
                    continuation.resume(throwing: ShortFormRequestError.because(url: url, cause: err))
                    return
                } else if let response, let urlResponse = response as? HTTPURLResponse {
                    continuation.resume(
                        throwing: ShortFormRequestError.httpStatus(
                            url: url, responseCode: urlResponse.statusCode
                        )
                    )
                    return
                }
                guard let data else {
                    continuation.resume(throwing: ShortFormRequestError.unexpected(
                        url: url, message: "segment request failed without a status code or real error"
                    ))
                    return
                }
                
                continuation.resume(returning: data)
            } // ... urlSession.dataTask
            
            task.resume()
        } // ... try await withCheckedThrowingContinuation
    }
}

internal class ShortFormMediaPlaylistGenerator {
    static let movieHeaderType: Data = "mvhd".data(using: .ascii)! // not a risky `!` with low-order chars
    // relative to the start of the box
    static let movieHeaderTimeScaleOffset: Int = 20
    // relative to the start of the box
    static let movieHeaderDurationOffset: Int = 24

    let initSegmentData: Data
    let playlistAttributes: PlaylistAttributes
    let originBase: URLComponents
    let cacheProxyBase: URLComponents
    
    func playlistString() throws -> String {
        // Reminder: If we are generating playlists from inside the loader delegate, we need to point at the Reverse Proxy from here, for each segment (including the init segment, which we don't want to fetch again)
        let originBaseURLStr = originBase.string!
        
        let preambleLines = [
            Tags.extM3U(),
            Tags.version(7),
            Tags.targetDuration(playlistAttributes.targetDuration),
            Tags.mediaSequence(startingFromSequenceNumber: 0),
            // TODO: Construct absolute URI? I think so, because we need to point to the reverse proxy
            Tags.map(uri: "\(originBaseURLStr)/init.mp4", range: nil),
//            Tags.map(uri: "init.mp4", range: nil),
            Tags.discontunityMarker()
        ]
        
        // TODO: Might want to check the trak's too, and take the longest duration(?)
        let mvhdDuration = try findMVHDDurationSec(mp4Data: initSegmentData)
        let segmentDuration = playlistAttributes.extinfSegmentDuration
            ?? Double(playlistAttributes.targetDuration)
        let segmentsPerStream = mvhdDuration / segmentDuration
        let numberOfSegments = ceil(segmentsPerStream) // including the last segment
        let wholeSegments = floor(segmentsPerStream)
        let lastSegmentDuration = (numberOfSegments - wholeSegments) * segmentDuration
        
        var segmentLines: [String] = []
        for segmentNumber in 0..<Int(wholeSegments) {
//            let segmentBasename = "\(segmentNumber).mp4"
            let segmentBasename = "\(originBaseURLStr)/\(segmentNumber).mp4"
            segmentLines.append(Tags.extinf(segmentDuration: segmentDuration, title: nil))
            segmentLines.append(segmentBasename)
        }
        // TODO: What if we don't have a last segment (ie, if lastSegmentDuration is 0, or 0 within some tolerance)
        segmentLines.append(Tags.extinf(segmentDuration: lastSegmentDuration, title: nil))
        segmentLines.append("\(originBaseURLStr)/\(Int(numberOfSegments - 1)).mp4")
        
        // TODO: ffmpeg always geneates one more segment with a really small duration. What is with that
        // i promise "postamble" is a real word
        let postambleLines = [
            Tags.endlist()
        ]
        
        let numSegUlp = segmentsPerStream.ulp
        let numSegNextUp = segmentsPerStream.nextUp
        let numSegNextDown = segmentsPerStream.nextDown
//        let segmentDurationByTargetOnly = Double(playlistAttributes.targetDuration)
//        let numberOfSegmentsByTargetOnly = mvhdDuration / segmentDurationByTargetOnly

        // What do we want here? The int-part of the number of segments, plus another segment with whatever is left (some fraction of a segment)
        
        // TODO: Last segment
        
        // Ok, now we need to 1) Extract the duration from the init segment data 2) use the power of division to get the duration in segments and 3) generate EXTINF/segment-urls for each and 4) Point to the caching proxy (for the proof-of-concept, can do this in all cases)
        
        return (preambleLines + segmentLines + postambleLines).joined(separator: "\n")
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
        let boxSize = try readInt32(data: mp4Data, at: boxStart)
        let boxEnd = Int32(boxStart) + boxSize // not inclusive
        guard boxEnd <= mp4Data.count else {
            throw ShortFormRequestError.unexpected(message: "mvhd end was out of bounds")
        }
        
        let timescaleStart = boxStart + ShortFormMediaPlaylistGenerator.movieHeaderTimeScaleOffset
        let durationStart = boxStart + ShortFormMediaPlaylistGenerator.movieHeaderDurationOffset
        let timescale = try readInt32(data: mp4Data, at: timescaleStart)
        let duration = try readInt32(data: mp4Data, at: durationStart)
        
        return Double(duration) / Double(timescale)
    }
    
    /// Reads an int32 out of the given data. The data is read big-endian because isobmff files are big-endian
    private func readInt32(data: Data, at offset: Int) throws -> Int32 {
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
        // TODO: Mux Video's target duration is 5sec, but the test assets have a duration of 4(ish), possibly because they were created from an source with a ~4.1sec keyframe interval (and/or accompanying sidx)
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
//        func map(uri: String, startingByte start: UInt?, offsetFromStart offset: UInt?) -> String {
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

// So what to do now?
//  1 Fetch the init segment and generate a media playlist from it
//  2 Cache the init segment in memory in the ReverseProxyServer
//  3 Find good criteria for evicting the init segment
//      * Maybe when the AssetLoaderDelegate is deinitialized? (except we control the lifecycle of it)
//      * CANNOT rely on LRU, since we don't ever want to re-fetch an init segment during play
//      * CANNOT rely on anything, this entire player sdk has no way to clean up its own resources, since you can't make deinitializers with extensions, so we have no control over the lifecycle of any object in the entire player, other than asking clients to call stopMonioring when their viewcontroller disappears (which they can't do in a feed becuase the view in the cell could be reused... unless they disable reusing the cells, which will lead to garbage performance)

/// Fetches the resource at the URL specified by the given URLRequest. Handles the state of the underlying URLSesisonTask,
/// canceling it if the parent task that started the fetch is ever canceled.
///
/// This class can only be used once. To make more requests, make more AsyncFetchers.
///
/// Start fetching with ``fetch`` and cancel either by canceling your parent Task or out-of-band using ``cancel``
internal actor AsyncFetcher {
    // TODO: Can also use this for the other segments when we replace GCDWebServer but we gotta add a callback to deliver the Data in segments as it arrives.. No need to check cancellation while handling those buffers, since our cancel() method also cancels the task
    let urlRequest: URLRequest
    let urlSession: URLSession
    
    private var fetchTask: Task<Data, any Error>?
    private var urlSessionTask: URLSessionTask?
    
    /// Fetches the resource specified by this actor's URLRequest. If the task was already started, awaits
    /// the existing ongoing task, otherwise starts a new one. The Task runs in the parent context, and
    /// cancels the URLSessionTask if it's canceled. You can also cancel out-of-band with ``cancel``
    func fetch() async throws -> Data {
        if let task = self.fetchTask {
            return try await task.value
        } else {
            let task = Task {
                return try await withTaskCancellationHandler(
                    operation: { return try await doFetch() },
                    onCancel: { Task.detached { await self.cancel() } }
                )
            }
            self.fetchTask = task
            return try await task.value
        }
    }
    
    /// Cancels the inner fetch task and url session task if required. Call to cancel stuff this Actor is doing from out-of-band
    func cancel() {
        // also called internally to handle the parent task of doFetch getting cancelled
        fetchTask?.cancel()
        urlSessionTask?.cancel()
    }
    
    /// handles cancellation if the parent task was canceled
    private func maybeHandleCancellation() throws {
        if Task.isCancelled {
            cancel()
            throw CancellationError()
        }
    }
    
    private func doFetch() async throws -> Data {
        try maybeHandleCancellation() // throw rather than start the task
        
        // TODO: wait, shit. MuxPlayerSwift is iOS 15+ so we can just use await urlSession.data() lmao
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            let url = urlRequest.url!
            let task = urlSession.dataTask(with: self.urlRequest) { data, response, err in
                if let err {
                    continuation.resume(throwing: ShortFormRequestError.because(url: url, cause: err))
                    return
                } else if let response, let urlResponse = response as? HTTPURLResponse {
                    continuation.resume(
                        throwing: RequestError.httpStatus(
                            url: url, responseCode: urlResponse.statusCode
                        )
                    )
                    return
                }
                guard let data else {
                    continuation.resume(throwing: RequestError.unexpected(
                        url: url, message: "segment request failed without a status code or real error"
                    ))
                    return
                }
                
                continuation.resume(returning: data)
            } // ... urlSession.dataTask
            
            task.resume()
            self.urlSessionTask = task
        } // ... try await withCheckedThrowingContinuation
        
        // in case the SC task was cancelled during the I/O. NSURLErrorCancelled isn't guaranteed 
        try maybeHandleCancellation()
        
        return data
    }

    init(
        urlRequest: URLRequest,
        urlSession: URLSession
    ) {
        self.urlRequest = urlRequest
        self.urlSession = urlSession
        self.fetchTask = nil
        self.urlSessionTask = nil
    }
    
    deinit {
        self.cancel()
    }
    
    enum RequestError: Error {
        case because(url: URL, cause: any Error)
        case httpStatus(url: URL, responseCode: Int)
        case unexpected(url: URL?, message: String)
    }
}
