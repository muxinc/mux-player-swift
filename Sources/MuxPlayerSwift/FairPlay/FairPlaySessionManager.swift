//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

protocol FairPlaySessionManager {
    
    // MARK: Requesting licenses and certs
    
    /// Requests the App Certificate for a playback id
    func requestCertificate(
        fromDomain rootDomain: String,
        playbackID: String,
        drmToken: String,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    )
    /// Requests a license to play based on the given SPC data
    /// - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String,
        offline _: Bool,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    )
    
    // MARK: registering drm-protected assets
    
    /// Adds a ``AVContentKeyRecipient`` (probably an ``AVURLAsset``)  that must be played
    /// with DRM protection. This call is necessary for DRM playback to succeed
    func addContentKeyRecipient(_ recipient: AVContentKeyRecipient)
    /// Removes a ``AVContentKeyRecipient`` previously added by ``addContentKeyRecipient``
    func removeContentKeyRecipient(_ recipient: AVContentKeyRecipient)
    /// Registers a ``PlaybackOptions`` for DRM playback, associated with the given playbackID
    func registerPlaybackOptions(_ opts: PlaybackOptions, for playbackID: String)
    /// Gets a DRM token previously registered via ``registerPlaybackOptions``
    func findRegisteredPlaybackOptions(for playbackID: String) -> PlaybackOptions?
    /// Unregisters a ``PlaybackOptions`` for DRM playback, given the assiciated playback ID
    func unregisterPlaybackOptions(for playbackID: String)
}

// MARK: helpers for interacting with the license server

extension DefaultFPSSManager {
    /// Generates a domain name appropriate for the Mux license proxy associted with the given
    /// "root domain". For example `mux.com` returns `license.mux.com` and
    /// `customdomain.xyz.com` returns `license.customdomain.xyz.com`
    static func makeLicenseDomain(_ rootDomain: String) -> String {
        let customDomainWithDefault = rootDomain
        let licenseDomain = "license.\(customDomainWithDefault)"
        
        // TODO: this check should not reach production or playing from staging will probably break
        if("staging.mux.com" == customDomainWithDefault) {
            return "license.gcp-us-west1-vos1.staging.mux.com"
        } else {
            return licenseDomain
        }
    }
    
    /// Generates an authenticated URL to Mux's license proxy, for a 'license' (a CKC for fairplay),
    /// for the given playabckID and DRM Token, at the given domain
    /// - SeeAlso ``makeLicenseDomain``
    static func makeLicenseURL(playbackID: String, drmToken: String, licenseDomain: String) -> URL {
        let baseStr = "https://\(licenseDomain)/license/fairplay/\(playbackID)?token=\(drmToken)"
        let url = URL(string: baseStr)
        return url!
    }
    
    /// Generates an authenticated URL to Mux's license proxy, for an application certificate, for the
    /// given plabackID and DRM token, at the given domain
    /// - SeeAlso ``makeLicenseDomain``
    static func makeAppCertificateURL(playbackID: String, drmToken: String, licenseDomain: String) -> URL {
        let baseStr = "https://\(licenseDomain)/appcert/fairplay/\(playbackID)?token=\(drmToken)"
        let url = URL(string: baseStr)
        return url!
    }
}

class DefaultFPSSManager: FairPlaySessionManager {
    
    private var playbackOptionsByPlaybackID: [String: PlaybackOptions] = [:]
    // note - null on simulators or other environments where fairplay isn't supported
    private let contentKeySession: AVContentKeySession?
    private let sessionDelegate: AVContentKeySessionDelegate?
    
    private let urlSession: URLSession
    
    func addContentKeyRecipient(_ recipient: AVContentKeyRecipient) {
        contentKeySession?.addContentKeyRecipient(recipient)
    }
    
    func removeContentKeyRecipient(_ recipient: AVContentKeyRecipient) {
        contentKeySession?.removeContentKeyRecipient(recipient)
    }
    
    // MARK: Requesting licenses and certs
    
    /// Requests the App Certificate for a playback id
    func requestCertificate(
        fromDomain rootDomain: String,
        playbackID: String,
        drmToken: String,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    ) {
        let url = DefaultFPSSManager.makeAppCertificateURL(
            playbackID: playbackID,
            drmToken: drmToken,
            licenseDomain: DefaultFPSSManager.makeLicenseDomain(rootDomain)
        )
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("Getting app cert from \(url)")
        let dataTask = urlSession.dataTask(with: request) { [requestCompletion] data, response, error in
            print("!--! APP CERT RESPONSE")
            var responseCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
                print("Cert response code: \(httpResponse.statusCode)")
                print("Cert response headers: ", httpResponse.allHeaderFields)
                if let errorBody = data {
                    let errorUtf = String(data: errorBody, encoding: .utf8)
                    print("Cert Error: \(errorUtf ?? "nil")")
                }
                
            }
            // error case: I/O failed
            if let error = error {
                print("Cert Request Failed: \(error.localizedDescription)")
                requestCompletion(Result.failure(
                    FairPlaySessionError.because(cause: error)
                ))
                return
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                print("Cert request failed: \(String(describing: responseCode))")
                requestCompletion(
                    Result.failure(
                        FairPlaySessionError.httpFailed(
                            responseStatusCode: responseCode ?? 0
                        )
                    )
                )
                return
            }
            guard let data = data else {
                print("Cert data unexpectedly nil from server")
                requestCompletion(Result.failure(
                    FairPlaySessionError.unexpected(message: "No cert data with 200 OK respone")
                ))
                return
            }
            
            print(">> App Cert Response data:\(data.base64EncodedString())")
            
            requestCompletion(Result.success(data))
        }
        
        dataTask.resume()
    }
    
    /// Requests a license to play based on the given SPC data
    /// - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String,
        offline _: Bool,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    ) {
        let url = DefaultFPSSManager.makeLicenseURL(
            playbackID: playbackID,
            drmToken: drmToken,
            licenseDomain: DefaultFPSSManager.makeLicenseDomain(rootDomain)
        )
        var request = URLRequest(url: url)
        
        // POST body is the SPC bytes
        request.httpMethod = "POST"
        request.httpBody = spcData
        
        // QUERY PARAMS
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(String(format: "%lu", request.httpBody?.count ?? 0), forHTTPHeaderField: "Content-Length")
        print("Sending License/CKC Request to: \(request.url?.absoluteString ?? "nil")")
        print("\t with header fields: \(String(describing: request.allHTTPHeaderFields))")
        
        let task = urlSession.dataTask(with: request) { [requestCompletion] data, response, error in
            print("<><> GOT LICENSE RESPONSE")
            var responseCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
                print("License response code: \(httpResponse.statusCode)")
                print("License response headers: ", httpResponse.allHeaderFields)
                
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                print("CKC request failed: \(String(describing: responseCode))")
                requestCompletion(Result.failure(TempError()))
                return
            }
            // error case: I/O failed
            if let error = error {
                print("URL Session Task Failed: \(error.localizedDescription)")
                requestCompletion(Result.failure(error)) // todo - real Error type
                return
            }
            // strange edge case: 200 with no response body
            //  this happened because of a client-side encoding difference causing an error
            //  with our drm vendor and probably shouldn't be reachable, but lets not crash
            guard let data = data else {
                print("No CKC data despite server returning success")
                requestCompletion(Result.failure(TempError())) // todo - real Error type
                return
            }
            
            let ckcData = data
            requestCompletion(Result.success(ckcData))
            print("")
        }
        task.resume()
    }
    
    // MARK: registering assets
    
    /// Registers a ``PlaybackOptions`` for DRM playback, associated with the given playbackID
    func registerPlaybackOptions(_ opts: PlaybackOptions, for playbackID: String) {
        print("Registering playbackID \(playbackID)")
        playbackOptionsByPlaybackID[playbackID] = opts
    }
    
    /// Gets a DRM token previously registered via ``registerPlaybackOptions``
    func findRegisteredPlaybackOptions(for playbackID: String) -> PlaybackOptions? {
        print("Finding playbackID \(playbackID)")
        return playbackOptionsByPlaybackID[playbackID]
    }
    
    /// Unregisters a ``PlaybackOptions`` for DRM playback, given the assiciated playback ID
    func unregisterPlaybackOptions(for playbackID: String) {
        print("UN-Registering playbackID \(playbackID)")
        playbackOptionsByPlaybackID.removeValue(forKey: playbackID)
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
            sessionDelegateQueue: DispatchQueue(label: "com.mux.player.fairplay"),
            urlSession: URLSession.shared
        )
    }
    
    init(
        contentKeySession: AVContentKeySession?,
        sessionDelegate: AVContentKeySessionDelegate?,
        sessionDelegateQueue: DispatchQueue,
        urlSession: URLSession
    ) {
        contentKeySession?.setDelegate(sessionDelegate, queue: sessionDelegateQueue)
        
        self.contentKeySession = contentKeySession
        self.sessionDelegate = sessionDelegate
        self.urlSession = urlSession
    }
}


// TODO: Final implementation needs something more verbose
class TempError: Error {
}

enum FairPlaySessionError : Error {
    case because(cause: Error)
    case httpFailed(responseStatusCode: Int)
    case noData(message: String)
    case unexpected(message: String)
}
