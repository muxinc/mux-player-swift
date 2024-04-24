//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

class FairplaySessionManager {
    
    // todo - unused, probably not needed unless you can get the AVURLAsset of a player
    static let AVURLAssetOptionsKeyDrmToken = "com.mux.player.drmtoken"
    
    private var drmAssetsByPlaybackId: [String: String] = [:]
    
    // note - null on simulators or other environments where fairplay isn't supported
    private let contentKeySession: AVContentKeySession?
    private let sessionDelegate: AVContentKeySessionDelegate?
    
    func addContentKeyRecipient(_ recipient: AVContentKeyRecipient) {
        contentKeySession?.addContentKeyRecipient(recipient)
    }
    
    func removeContentKeyRecipient(_ recipient: AVContentKeyRecipient) {
        contentKeySession?.removeContentKeyRecipient(recipient)
    }
    
    // MARK: Requesting licenses and certs
    
    /// Requests the App Certificate for a playback id
    func requestCertificate(playbackID: String, drmToken: String, completion: (Result<Data, Error>) -> Void) {
        // todo - request app certficate from the backend
        let tempCert = ProcessInfo.processInfo.environment["APP_CERT_BASE64"]
        print("CERTIFICATE :: app cert is \(tempCert)")
        
        guard let tempCert = tempCert else {
            completion(Result.failure(CancellationError())) // todo - a real Error type
            return
        }
        
        let certData = Data(base64Encoded: tempCert)!
        print("CERTIFICATE :: Delivering App Certificate")
        completion(Result.success(certData))
    }
    
    /// Requests a license to play based on the given SPC data
    func requestLicense(spcData: Data, playbackID: String, drmToken: String?, offline: Bool, completion: (Result<Data, Error>) -> Void) {
        // todo request license from backend for the playback id, drmToken, and spc data
    }
    
    // MARK: registering assets
    
    /// Registers a DRM Token as belonging to a playback ID.
    func registerDrmToken(_ token: String, for playbackID: String) {
        // todo - i wonder if the cache branch has a handy function for extracting playback ids
        drmAssetsByPlaybackId[playbackID] = token
    }
    
    /// Gets a DRM token previously registered via ``registerDrmToken``
    func drmToken(for playbackID: String) -> String? {
        return drmAssetsByPlaybackId[playbackID]
    }
    
    /// Registers a DRM Token as belonging to a playback ID.
    func unregisterDrmToken(for playabckID: String) {
        drmAssetsByPlaybackId.removeValue(forKey: playabckID)
    }
    
    // MARK: initializers
    
    convenience init() {
#if targetEnvironment(simulator)
        let session: AVContentKeySession? = nil
        let delegate: AVContentKeySessionDelegate? = nil
#else
        let session = AVContentKeySession(keySystem: .fairPlayStreaming)
        let delegate = ContentKeySessionDelegate()
#endif
        
        self.init(
            contentKeySession: session,
            sessionDelegate: delegate,
            sessionDelegateQueue: DispatchQueue(label: "com.mux.player.fairplay")
        )
    }
    
    init(
        contentKeySession: AVContentKeySession?,
        sessionDelegate: AVContentKeySessionDelegate?,
        sessionDelegateQueue: DispatchQueue
    ) {
        print(">>>>>>>>>>>>>>>>>")
        print(ProcessInfo.processInfo.environment["APP_CERT_BASE64"])
        
        contentKeySession?.setDelegate(sessionDelegate, queue: sessionDelegateQueue)
        
        self.contentKeySession = contentKeySession
        self.sessionDelegate = sessionDelegate
    }
}
