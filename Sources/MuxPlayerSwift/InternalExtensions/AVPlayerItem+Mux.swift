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
        
        // TODO: Delegate here
        
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

internal class ShortFormAssetLoaderDelegate :
    NSObject, AVAssetResourceLoaderDelegate {
    
    // TODO: same as in the ReverseProxyServer, but maybe we have PlayerSDK specify this for consistency
    let urlSession: URLSession = URLSession.shared
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        if let url = loadingRequest.request.url,
            isURLForShortform(url: url) {
            let initSegmentURL = makeInitSegmentURL(playlistURL: url)
            PlayerSDK.shared.diagnosticsLogger.info(
                "[shorform-test] initSegmentURL: \(initSegmentURL.absoluteString)"
            )
            
            // check if init segment is cached already
            // Get init segment from wherever it's needed
            // cache init segment in the reverse proxy
            // generate playlist from
            
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
        let playbackID = playlistURL.pathComponents[2]
        let host = playlistURL.host
        
        var urlComponents = URLComponents()
        urlComponents.host = host
        urlComponents.path = "short-form-tests/v1/\(playbackID)/init.mp4"
        
        return urlComponents.url! // TODO: yknow, maybe handle
    }
    
    private func fetchInitSegment(initSegURL url: URL) throws -> Data {
        let request = URLRequest(url: url)
        
        var segmentData: Data?
        var responseCode: Int?
        var error: Error?
        
        // you're allowed to be synchronous in an ResourceLoaderDelegate, so be synchronous
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        urlSession.dataTask(with: request) { data, response, err in
            if let err {
                error = err
            } else if let response, let urlResponse = response as? HTTPURLResponse {
                responseCode = urlResponse.statusCode
            }
            guard let data else {
                return
            }
            
            segmentData = data
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        
        if let segmentData {
            return segmentData
        } else {
            if let responseCode {
                throw ShortFormRequestError.httpStatus(url: url, responseCode: responseCode)
            } else if let error {
                throw ShortFormRequestError.because(url: url, cause: error)
            } else {
                throw ShortFormRequestError.unexpected(url: url, message: "failed with no info (womp)")
            }
        }
    }
}

internal class ShortFormMediaPlaylistGenerator {
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

