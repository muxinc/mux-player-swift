//
//  File.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 8/18/25.
//

import Foundation
import AVFoundation

/// Standalone `AVContentKeySessionDelegate` for use with Mux Video's FairPlay streaming.
/// Use this if you aren't using any of our `AVPlayerViewController`, `AVPlayerLayer`, or `AVPlayerItem` extensions in your app
/// As with any other `AVContentKeySessionDelegate`, your app must own instances of this class. AVFoundation objects hold only weak references to it
/// - Note: If you're using Mux Player's ``AVPlayerLayer`` or ``AVPlayerViewController`` extensions, you don't need to use this object. Just choose ``PlaybackOptions.PlaybackPolicy.drm`` when creating your `AVPlayerLayer` or `AVPlayerViewController`
/// - Note: Mux Video does not support ClearKey DRM. If you use this object on a simulator, playback will fail
/// - SeeAlso:
///   - ``AVPlayerViewController.init(playbackID:, playbackOptions:)``
///   - ``AVPlayerLayer.init(playbackID:, playbackOptions:)``
class MuxFairPlayContentKeySessionDelegate: NSObject, AVContentKeySessionDelegate {
    
    // We wrap our internal delegate in a facade so we don't have to expose the internal plumbing in our
    // ContentKeySessionDelegate, which mostly exists for testability and isn't useful to customers
    private let internalDelegate: ContentKeySessionDelegate< DefaultFairPlayStreamingSessionManager<AVContentKeySession>
    >?
    private let sessionManager: DefaultFairPlayStreamingSessionManager<AVContentKeySession>
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didProvide keyRequest: AVContentKeyRequest
    ) {
        internalDelegate?.contentKeySession(session, didProvide: keyRequest)
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest
    ) {
        internalDelegate?.contentKeySession(session, didProvideRenewingContentKeyRequest: keyRequest)
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest
    ) {
        internalDelegate?.contentKeySession(session, contentKeyRequestDidSucceed: keyRequest)
    }
    
    func contentKeySession(
        _ session: AVContentKeySession, contentKeyRequest
        keyRequest: AVContentKeyRequest, didFailWithError
        err: any Error
    ) {
        internalDelegate?.contentKeySession(session, contentKeyRequest: keyRequest, didFailWithError: err)
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        shouldRetry keyRequest: AVContentKeyRequest,
        reason retryReason: AVContentKeyRequest.RetryReason
    ) -> Bool {
        if let internalDelegate = self.internalDelegate {
            return internalDelegate.contentKeySession(
                session, shouldRetry: keyRequest, reason: retryReason
            )
        } else {
            return false
        }
    }
    
    private func makeFairPlayContentKeySession() -> AVContentKeySession {
        return AVContentKeySession(keySystem: .fairPlayStreaming)
    }
    
    private func makeClearKeyContentKeySession() -> AVContentKeySession {
        return AVContentKeySession(keySystem: .clearKey)
    }

    /// Make a new instance for the given Mux PlaybackID, using the given playback and DRM tokens
    /// - SeeAlso: https://www.mux.com/docs/guides/mux-player-ios#secure-your-playback-experience
    init(playbackID: String, playbackToken: String, drmToken: String) {
        #if targetEnvironment(simulator)
        // Creating an AVContentKeySession for fairplay will cause a silent crash on simulators, so
        //  we stub out functionality using a .clearKey session and dummy session delegate
        self.sessionManager = DefaultFairPlayStreamingSessionManager(
            contentKeySession: AVContentKeySession(keySystem: .clearKey),
            urlSession: .shared,
            errorDispatcher: PlayerSDK.shared.monitor
        )
        self.internalDelegate = nil
        #else
        self.sessionManager = DefaultFairPlayStreamingSessionManager(
            contentKeySession: AVContentKeySession(keySystem: .fairPlayStreaming),
            urlSession: .shared,
            errorDispatcher: PlayerSDK.shared.monitor
        )
        self.internalDelegate = ContentKeySessionDelegate(sessionManager: self.sessionManager)
        #endif
        
        self.sessionManager.sessionDelegate = self.internalDelegate
        
        // The SessionManager must have these registered in order for the ContentKeySessionDelegate to
        //  find the playback and DRM tokens
        let options = PlaybackOptions(playbackToken: playbackToken, drmToken: drmToken)
        self.sessionManager.registerPlaybackOptions(options, for: playbackID)
        
        super.init()
    }
}
