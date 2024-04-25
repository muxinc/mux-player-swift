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
    
    private var playbackOptionsByPlaybackID: [String: PlaybackOptions] = [:]
    // note - null on simulators or other environments where fairplay isn't supported
    private let contentKeySession: AVContentKeySession?
    private let sessionDelegate: AVContentKeySessionDelegate?
    
    private let urlSession = URLSession.shared
    
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
    
//    static func encode(value url: String?) -> String {
//        let queryKeyValueString = CharacterSet(charactersIn: ":?=&+").inverted
//        return url?.addingPercentEncoding(withAllowedCharacters: queryKeyValueString) ?? ""
//    }
    
    /// Requests a license to play based on the given SPC data
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        domain: String,
        offline: Bool, 
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // no need to track license request tasks since we are not prewarming
        //  and we don't need to worry about re-joinining any existing license
        //  reqs.
        
        var request = URLRequest(url: licenseURL(playbackId: playbackID, drmToken: drmToken, domain: domain))
        request.httpMethod = "POST"
        
        // todo - Do we need special encoding options? like with padding or newlines
        let spcDataBase64 = spcData.base64EncodedString()
        request.httpBody = spcDataBase64.data(using: .utf8, allowLossyConversion: true)
        
        let task = urlSession.dataTask(with: request) { [completion] data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                let responseCode = httpResponse.statusCode
                print("License response: \(httpResponse.statusCode)")

                let responseBody = data?.base64EncodedString()
                print("License response body: ", responseBody!)
                print("License response headers: ", httpResponse.allHeaderFields)
            }
            
            if let error = error {
                print("URL Session Task Failed: %@", error.localizedDescription)
                completion(Result.failure(error)) // todo - real Error type
                return
            }
            
            if let ckcData = data {
                let ckcMessage = Data(base64Encoded: ckcData)
                
                // Also log the CKC
                let ckcBase64 = ckcData.base64EncodedString()
                print("CKC Response Body base64:", ckcBase64)
                
                completion(Result.success(ckcData))
            } else {
                completion(Result.failure(CancellationError())) // todo - real Error Type
            }
        }
        task.resume()
    }
    
    // MARK: registering assets
    
    /// Registers a ``PlaybackOptions`` for DRM playback, associated with the given playbackID
    func registerPlaybackOptions(_ token: PlaybackOptions, for playbackID: String) {
        // todo - i wonder if the cache branch has a handy function for extracting playback ids
        playbackOptionsByPlaybackID[playbackID] = token
    }
    
    /// Gets a DRM token previously registered via ``registerDrmToken``
    func findRegisteredPlaybackOptions(for playbackID: String) -> PlaybackOptions? {
        return playbackOptionsByPlaybackID[playbackID]
    }
    
    /// Unregisters a ``PlaybackOptions`` for DRM playback, given the assiciated playback ID
    func unregisterPlaybackOptions(for playabckID: String) {
        playbackOptionsByPlaybackID.removeValue(forKey: playabckID)
    }
    
    // MARK: helpers
    
    private func licenseURL(playbackId: String, drmToken: String, domain: String) -> URL {
        let baseStr = "https://\(domain)/fairplay/\(playbackId)?token=\(drmToken)"
        let url = URL(string: baseStr)
        return url!
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
//        print(">>>>>>>>>>>>>>>>>")
//        print(ProcessInfo.processInfo.environment["APP_CERT_BASE64"])
        
        contentKeySession?.setDelegate(sessionDelegate, queue: sessionDelegateQueue)
        
        self.contentKeySession = contentKeySession
        self.sessionDelegate = sessionDelegate
    }
}
