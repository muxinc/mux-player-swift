//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

// MARK: - FairPlayStreamingSessionManager

protocol FairPlayStreamingSessionCredentialClient: AnyObject {
    // MARK: Requesting licenses and certs

    // Requests the App Certificate for a playback id
    func requestCertificate(
        fromDomain rootDomain: String,
        playbackID: String,
        drmToken: String,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    )
    // Requests a license to play based on the given SPC data
    // - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String,
        offline _: Bool,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    )
}

protocol PlaybackOptionsRegistry {
    /// Registers a ``PlaybackOptions`` for DRM playback, associated with the given playbackID
    func registerPlaybackOptions(_ opts: PlaybackOptions, for playbackID: String)
    /// Gets a DRM token previously registered via ``registerPlaybackOptions``
    func findRegisteredPlaybackOptions(for playbackID: String) -> PlaybackOptions?
    /// Unregisters a ``PlaybackOptions`` for DRM playback, given the assiciated playback ID
    func unregisterPlaybackOptions(for playbackID: String)
}

// MARK: registering drm-protected assets
protocol ContentKeyRecipientRegistry {
    /// Adds a ``AVContentKeyRecipient`` (probably an ``AVURLAsset``)  that must be played
    /// with DRM protection. This call is necessary for DRM playback to succeed
    func addContentKeyRecipient(_ recipient: AVContentKeyRecipient)
    /// Removes a ``AVContentKeyRecipient`` previously added by ``addContentKeyRecipient``
    func removeContentKeyRecipient(_ recipient: AVContentKeyRecipient)
}

typealias FairPlayStreamingSessionManager = FairPlayStreamingSessionCredentialClient & PlaybackOptionsRegistry & ContentKeyRecipientRegistry

// MARK: - Content Key Provider

// Define protocol for calls made to AVContentKeySession
protocol ContentKeyProvider {
    func setDelegate(
        _ delegate: (any AVContentKeySessionDelegate)?,
        queue delegateQueue: dispatch_queue_t?
    )

    func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient)

    func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient)
}

// AVContentKeySession already has built-in definitions for
// these methods so this declaration can be empty
extension AVContentKeySession: ContentKeyProvider { }

// TODO: make this functional, if necessary
class ClearContentKeyProvider {
    var delegate: (any AVContentKeySessionDelegate)?
    var delegateQueue: dispatch_queue_t?
}

extension ClearContentKeyProvider: ContentKeyProvider {
    func setDelegate(
        _ delegate: (any AVContentKeySessionDelegate)?,
        queue delegateQueue: dispatch_queue_t?
    ) {
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }

    func addContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        // no-op
    }

    func removeContentKeyRecipient(_ recipient: any AVContentKeyRecipient) {
        // no-op
    }
}

// MARK: - DefaultFairPlayStreamingSessionManager

// MARK: helpers for interacting with the license server

extension String {
    // Generates a domain name appropriate for the Mux license proxy associted with the given
    // "root domain". For example `mux.com` returns `license.mux.com` and
    // `customdomain.xyz.com` returns `license.customdomain.xyz.com`
    static func makeLicenseDomain(rootDomain: String) -> Self {
        let customDomainWithDefault = rootDomain
        let licenseDomain = "license.\(customDomainWithDefault)"

        // TODO: this check should not reach production or playing from staging will probably break
        if("staging.mux.com" == customDomainWithDefault) {
            return "license.gcp-us-west1-vos1.staging.mux.com"
        } else {
            return licenseDomain
        }
    }
}

extension URL {
    // Generates an authenticated URL to Mux's license proxy, for a 'license' (a CKC for fairplay),
    // for the given playabckID and DRM Token, at the given domain
    // - SeeAlso ``init(playbackID:,drmToken:,applicationCertificateLicenseDomain:)``
    init(
        playbackID: String,
        drmToken: String,
        licenseDomain: String
    ) {
        let absoluteString = "https://\(licenseDomain)/license/fairplay/\(playbackID)?token=\(drmToken)"
        self.init(string: absoluteString)!
    }

    // Generates an authenticated URL to Mux's license proxy, for an application certificate, for the
    // given plabackID and DRM token, at the given domain
    // - SeeAlso ``init(playbackID:,drmToken:,licenseDomain: String)``
    init(
        playbackID: String,
        drmToken: String,
        applicationCertificateLicenseDomain: String
    ) {
        let absoluteString = "https://\(applicationCertificateLicenseDomain)/appcert/fairplay/\(playbackID)?token=\(drmToken)"
        self.init(string: absoluteString)!
    }
}

class DefaultFairPlayStreamingSessionManager<ContentKeySession: ContentKeyProvider>: FairPlayStreamingSessionManager {

    private var playbackOptionsByPlaybackID: [String: PlaybackOptions] = [:]
    // note - null on simulators or other environments where fairplay isn't supported
    private let contentKeySession: ContentKeySession?

    var sessionDelegate: AVContentKeySessionDelegate? {
        didSet {
            contentKeySession?.setDelegate(
                sessionDelegate,
                queue: DispatchQueue(
                    label: "com.mux.player.fairplay"
                )
            )
        }
    }

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
        let url = URL(
            playbackID: playbackID,
            drmToken: drmToken,
            applicationCertificateLicenseDomain: String.makeLicenseDomain(
                rootDomain: rootDomain
            )
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
            // this edge case (200 with invalid data) is possible from our DRM vendor
            guard let data = data,
                  data.count > 0 else {
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
        let url = URL(
            playbackID: playbackID,
            drmToken: drmToken,
            licenseDomain: String.makeLicenseDomain(
                rootDomain: rootDomain
            )
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
            // error case: I/O failed
            if let error = error {
                print("URL Session Task Failed: \(error.localizedDescription)")
                requestCompletion(Result.failure(
                    FairPlaySessionError.because(cause: error)
                ))
                return
            }
            
            var responseCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
                print("License response code: \(httpResponse.statusCode)")
                print("License response headers: ", httpResponse.allHeaderFields)
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                print("CKC request failed: \(String(describing: responseCode))")
                requestCompletion(Result.failure(
                    FairPlaySessionError.httpFailed(
                        responseStatusCode: responseCode ?? 0
                    )
                ))
                return
            }
            // strange edge case: 200 with no response body
            //  this happened because of a client-side encoding difference causing an error
            //  with our drm vendor and probably shouldn't be reachable, but lets not crash
            guard let data = data,
                  data.count > 0
            else {
                print("No CKC data despite server returning success")
                requestCompletion(Result.failure(
                    FairPlaySessionError.unexpected(message: "No license data with 200 response")
                ))
                return
            }
            
            let ckcData = data
            requestCompletion(Result.success(ckcData))
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

    init(
        contentKeySession: ContentKeySession,
        urlSession: URLSession
    ) {
        self.contentKeySession = contentKeySession
        self.urlSession = urlSession
    }
}

internal extension DefaultFairPlayStreamingSessionManager where ContentKeySession == ClearContentKeyProvider {
    convenience init() {
        self.init(
            contentKeySession: ClearContentKeyProvider(),
            urlSession: URLSession.shared
        )
        let delegate = ContentKeySessionDelegate(
            sessionManager: self
        )
        self.sessionDelegate = delegate
    }
}

internal extension DefaultFairPlayStreamingSessionManager where ContentKeySession == AVContentKeySession {
    convenience init() {
        self.init(
            contentKeySession: AVContentKeySession(
                keySystem: .fairPlayStreaming
            ),
            urlSession: URLSession.shared
        )
        let delegate = ContentKeySessionDelegate(
            sessionManager: self
        )
        self.sessionDelegate = delegate
    }
}

// MARK: - FairPlaySessionError

enum FairPlaySessionError : Error {
    case because(cause: any Error)
    case httpFailed(responseStatusCode: Int)
    case unexpected(message: String)
}
