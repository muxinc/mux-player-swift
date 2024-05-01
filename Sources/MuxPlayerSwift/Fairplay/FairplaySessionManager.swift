//
//  FairplaySessionManager.swift
//
//
//  Created by Emily Dixon on 4/19/24.
//

import Foundation
import AVFoundation

class FairplaySessionManager {
    
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
    func requestCertificate(
        fromDomain rootDomain: String,
        playbackID: String,
        drmToken: String,
        completion requestCompletion: @escaping (Result<Data, Error>) -> Void
    ) {
        let url = makeAppCertificateURL(
            playbackId: playbackID,
            drmToken: drmToken,
            licenseDomain: makeLicenseDomain(rootDomain)
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
                    print("Cert Error: \(errorUtf)")
                }
                
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                print("Cert request failed: \(responseCode)")
                requestCompletion(Result.failure(TempError()))
                return
            }
            // error case: I/O failed
            if let error = error {
                print("Cert Request Failed: \(error.localizedDescription)")
                requestCompletion(Result.failure(error)) // todo - real Error type
                return
            }
            // strange edge case: 200 with no response body
            guard let data = data else {
                print("No cert data despite server returning success")
                requestCompletion(Result.failure(TempError())) // todo - real Error type
                return
            }
            
            print(">> App Cert Response data:\(data.base64EncodedString())")
            
            requestCompletion(Result.success(data))
        }
        
        dataTask.resume()
    }
    
    /// Requests a license to play based on the given SPC data
    /// - parameter playbackDomain - Domain for the playback URL, (eg, stream.mux.com or a custom domain)
    /// - parameter offline - Not currently used, may not ever be used in short-term, maybe delete?
    func requestLicense(
        spcData: Data,
        playbackID: String,
        drmToken: String,
        rootDomain: String,
        offline _: Bool,
        completion licenseRequestComplete: @escaping (Result<Data, Error>) -> Void
    ) {
        let url = makeLicenseURL(
            playbackId: playbackID,
            drmToken: drmToken,
            licenseDomain: makeLicenseDomain(rootDomain)
        )
        var request = URLRequest(url: url)
        
        // POST body is the SPC bytes
        request.httpMethod = "POST"
        request.httpBody = spcData
        //print("Raw (non-percent encoded) SPC base64:", spcData.base64EncodedString()) // we dump the encoded version too
        
        
        // QUERY PARAMS
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(String(format: "%lu", request.httpBody?.count ?? 0), forHTTPHeaderField: "Content-Length")
        print("Sending License/CKC Request to: \(request.url?.absoluteString)")
        print("\t with header fields: \(request.allHTTPHeaderFields)")
        
        let task = urlSession.dataTask(with: request) { [licenseRequestComplete] data, response, error in
            print("<><> GOT LICENSE RESPONSE")
            var responseCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
                print("License response code: \(httpResponse.statusCode)")
                print("License response headers: ", httpResponse.allHeaderFields)
                
            }
            // error case: I/O finished with non-successful response
            guard responseCode == 200 else {
                print("CKC request failed: \(responseCode)")
                licenseRequestComplete(Result.failure(TempError()))
                return
            }
            // error case: I/O failed
            if let error = error {
                print("URL Session Task Failed: \(error.localizedDescription)")
                licenseRequestComplete(Result.failure(error)) // todo - real Error type
                return
            }
            // strange edge case: 200 with no response body
            //  this happened because of a client-side encoding difference causing an error
            //  with our drm vendor and probably shouldn't be relevant, but lets not crash
            guard let data = data else {
                print("No CKC data despite server returning success")
                licenseRequestComplete(Result.failure(TempError())) // todo - real Error type
                return
            }
            
            let responseBody = data
            print("License response body: ", responseBody)
            
            let ckcData = data
            print("")
            licenseRequestComplete(Result.success(ckcData))
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
    
    // MARK: helpers
    
    private func makeLicenseDomain(_ rootDomain: String) -> String {
        let customDomainWithDefault = rootDomain ?? "mux.com"
        let licenseDomain = "license.\(customDomainWithDefault)"
        
        // TODO: this check should not reach production or playing from staging will probably break
        if("staging.mux.com" == customDomainWithDefault) {
            return "license.gcp-us-west1-vos1.staging.mux.com"
        } else {
            return licenseDomain
        }
    }
    
    private func makeLicenseURL(playbackId: String, drmToken: String, licenseDomain: String) -> URL {
        let baseStr = "https://\(licenseDomain)/license/fairplay/\(playbackId)?token=\(drmToken)"
        let url = URL(string: baseStr)
        return url!
    }
    
    private func makeAppCertificateURL(playbackId: String, drmToken: String, licenseDomain: String) -> URL {
        let baseStr = "https://\(licenseDomain)/appcert/fairplay/\(playbackId)?token=\(drmToken)"
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
        // TODO: Remove when app cert endpoint is available
        //        print(">>>>>>>>>>>>>>>>>")
        //        print(ProcessInfo.processInfo.environment["APP_CERT_BASE64"])
        
        contentKeySession?.setDelegate(sessionDelegate, queue: sessionDelegateQueue)
        
        self.contentKeySession = contentKeySession
        self.sessionDelegate = sessionDelegate
    }
}


// TODO: Final implementation needs something more verbose
class TempError: Error {
}
