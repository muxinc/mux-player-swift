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
            Task.detached { [self] in
                let segmentData = try await fetchInitSegment(initSegmentURL: initSegmentURL)
                PlayerSDK.shared.diagnosticsLogger.debug("resourceLoader fetched \(segmentData.count) bytes")
                
                let playlistData = Data() // TODO
                loadingRequest.dataRequest!.respond(with: playlistData)
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
    
    private func fetchInitSegment(initSegmentURL url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse // TODO: unchecked cast safe in practice but eep
        
        PlayerSDK.shared.diagnosticsLogger.debug("fetchInitSegment: response code \(httpResponse.statusCode)")
        
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
    static let mvhdPattern: Data = "mvhd".data(using: .utf8)!
    
    let initSegmentData: Data
    
    init(initSegment: Data) {
        self.initSegmentData = initSegment
    }
}

internal enum ShortFormRequestError: Error {
    case because(url: URL, cause: any Error)
    case httpStatus(url: URL, responseCode: Int)
    case unexpected(url: URL?, message: String)
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
