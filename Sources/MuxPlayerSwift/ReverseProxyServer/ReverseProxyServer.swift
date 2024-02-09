//
//  ReverseProxyServer.swift
//

import Foundation

import GCDWebServer

class ReverseProxyServer {

    class EventRecorder {

        func didRecord(event: ReverseProxyEvent) {
            print("RPS - \(Date()) - \(event.description)")
        }

    }

    class PlaylistLocalURLMapper {
        let port: UInt = 1234
        let originURLKey: String = "__hls_origin_url"

        func reversifyManifest(
            encodedManifest: Data,
            manifestOriginURL: URL
        ) -> Data? {
            let originalManifest = String(
                data: encodedManifest,
                encoding: .utf8
            )

            let parsedManifest = originalManifest?
                .components(separatedBy: .newlines)
                .map { line in self.processPlaylistLine(line, forOriginURL: manifestOriginURL) }
                .joined(separator: "\n")

            return parsedManifest?.data(using: .utf8)
        }

        func processPlaylistLine(
            _ line: String,
            forOriginURL originURL: URL
        ) -> String {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return line }

            if line.hasPrefix("#") {
                if line.hasPrefix("#EXT") {
                    return lineByReplacingURI(line: line, forOriginURL: originURL)
                } else {
                    return line
                }
            }

            if let originalSegmentURL = absoluteURL(from: line, forOriginURL: originURL),
               let reverseProxyURL = reverseProxyURL(from: originalSegmentURL) {
                return reverseProxyURL.absoluteString
            }
            return line
        }

        func lineByReplacingURI(
            line: String,
            forOriginURL originURL: URL
        ) -> String {
            let uriPattern = try! NSRegularExpression(pattern: "URI=\"([^\"]*)\"")
            let lineRange = NSRange(location: 0, length: line.count)
            guard let result = uriPattern.firstMatch(in: line, options: [], range: lineRange) else { return line }

            let uri = (line as NSString).substring(with: result.range(at: 1))
            guard let absoluteURL = absoluteURL(from: uri, forOriginURL: originURL) else { return line }
            guard let reverseProxyURL = reverseProxyURL(from: absoluteURL) else { return line }

            return uriPattern.stringByReplacingMatches(in: line, options: [], range: lineRange, withTemplate: "URI=\"\(reverseProxyURL.absoluteString)\"")
        }

        func absoluteURL(from line: String, forOriginURL originURL: URL) -> URL? {
            if line.hasPrefix("http://") || line.hasPrefix("https://") {
                return URL(string: line)
            }

            guard let scheme = originURL.scheme,
                  let host = originURL.host
            else {
                print("Error: bad url")
                return nil
            }

            let path: String
            if line.hasPrefix("/") {
                path = line
            } else {
                path = originURL.deletingLastPathComponent().appendingPathComponent(line).path
            }

            return URL(string: scheme + "://" + host + path)?.standardized
        }

        func reverseProxyURL(from originURL: URL) -> URL? {
            guard var components = URLComponents(url: originURL, resolvingAgainstBaseURL: false) else { return nil }
            components.scheme = "http"
            components.host = "127.0.0.1"
            components.port = Int(port)

            let originURLQueryItem = URLQueryItem(name: originURLKey, value: originURL.absoluteString)
            components.queryItems = (components.queryItems ?? []) + [originURLQueryItem]

            return components.url
        }
    }

    var session: URLSession = .shared
    var webServer: GCDWebServer

    var segmentCache: URLCache

    var eventRecorder: EventRecorder = EventRecorder()
    var manifestReversifier: PlaylistLocalURLMapper = PlaylistLocalURLMapper()

    let port: UInt = 1234
    let originURLKey: String = "__hls_origin_url"

    let defaultDiskCapacity = 256_000_000

    init() {
        self.webServer = GCDWebServer()

        self.segmentCache = URLCache(
            memoryCapacity: 0,
            diskCapacity: defaultDiskCapacity
        )
    }

    func start() {
        guard !webServer.isRunning else {
            return
        }

        self.setupManifestRequestHandler()
        self.setupSegmentHandler()

        webServer.start(
            withPort: port,
            bonjourName: nil
        )
    }

    func stop() {
        guard webServer.isRunning else {
            return
        }

        webServer.stop()
    }

    private func originURL(
        from request: GCDWebServerRequest
    ) -> URL? {

        guard let encodedString = request.query?[originURLKey] else {
            return nil
        }

        return URL(string: encodedString)
    }

    private func setupManifestRequestHandler() {
        self.webServer.addHandler(
            forMethod: "GET",
            pathRegex: "^/.*\\.*$",
            request: GCDWebServerRequest.self
        ) { [weak self] (request: GCDWebServerRequest, completion) in
            guard let self = self,
            let originURL = originURL(from: request) else {
                completion(
                    GCDWebServerErrorResponse(
                        statusCode: 400
                    )
                )
                return
            }

            eventRecorder.didRecord(
                event: ReverseProxyEvent(
                    originURL: originURL,
                    kind: .manifestRequestReceived
                )
            )

            if originURL.pathExtension == "m3u8" {
                let task = session.dataTask(
                    with: originURL
                ) { data, response, error in

                    guard let data = data,
                          let response = response,
                          let mimeType = response.mimeType
                    else {
                        return completion(GCDWebServerErrorResponse(statusCode: 500))
                    }

                    // Swap playlist entries to use proxied URLs
                    guard let parsedManifest = self.manifestReversifier.reversifyManifest(
                        encodedManifest: data,
                        manifestOriginURL: originURL
                    ) else {
                        return completion(
                            GCDWebServerErrorResponse(
                                statusCode: 500
                            )
                        )
                    }

                    let contentType = response.mimeType ?? "application/x-mpegurl"

                    return completion(
                        GCDWebServerDataResponse(
                            data: parsedManifest,
                            contentType: contentType
                        )
                    )
                }

                task.resume()
            }


        }

    }

    private func setupSegmentHandler() {
        self.webServer.addHandler(
            forMethod: "GET",
            pathRegex: "^/.*\\.ts$",
            request: GCDWebServerRequest.self
        ) { [weak self] request, completion in

            guard let self = self else {
                return completion(GCDWebServerDataResponse(statusCode: 500))
            }

            guard let originURL = self.originURL(from: request) else {
                return completion(GCDWebServerErrorResponse(statusCode: 400))
            }

            eventRecorder.didRecord(
                event: ReverseProxyEvent(
                    originURL: originURL,
                    kind: .segmentRequestReceived
                )
            )

            var reverseProxyRequest = URLRequest(url: originURL)
            reverseProxyRequest.httpMethod = "GET"

            // Construct a modified request that will be the
            // same across segment requests
            // - Remove query parameters
            // - Replace cdn-specific hosts with generic
            //
            // This request only used as a cache key
            var components = URLComponents(url: originURL, resolvingAgainstBaseURL: false)
            components?.queryItems = nil
            components?.host = "stream.mux.com"

            var strippedRequest = URLRequest(url: components!.url!)

            if let cachedResponse = self.segmentCache.cachedResponse(
                for: strippedRequest
            ) {

                eventRecorder.didRecord(
                    event: ReverseProxyEvent(
                        originURL: originURL,
                        kind: .segmentCacheHit(key: strippedRequest)
                    )
                )

                let contentType = cachedResponse.response.mimeType ?? "video/mp2t"

                completion(
                    GCDWebServerDataResponse(
                        data: cachedResponse.data,
                        contentType: contentType
                    )
                )
            } else {

                eventRecorder.didRecord(
                    event: ReverseProxyEvent(
                        originURL: originURL,
                        kind: .segmentCacheMiss(key: strippedRequest)
                    )
                )

                let task = self.session.dataTask(
                    with: reverseProxyRequest
                ) { [weak self] data, response, error in

                    guard let self = self else {
                        completion(
                            GCDWebServerErrorResponse(
                                statusCode: 400
                            )
                        )
                        return
                    }

                    guard let data = data, let response = response else {
                        return completion(GCDWebServerErrorResponse(statusCode: 500))
                    }

                    let contentType = response.mimeType ?? "video/mp2t"
                    completion(
                        GCDWebServerDataResponse(
                            data: data,
                            contentType: contentType
                        )
                    )

                    let cachedURLResponse = CachedURLResponse(
                        response: response,
                        data: data
                    )

                    self.segmentCache.storeCachedResponse(
                        cachedURLResponse,
                        for: strippedRequest
                    )

                    let segmentSizeInBytes = data.count

                    let cacheDiskUsageInBytes = self.segmentCache.currentDiskUsage

                    self.eventRecorder.didRecord(
                        event: ReverseProxyEvent(
                            originURL: originURL,
                            kind: .segmentCacheStored(
                                key: strippedRequest,
                                cacheDiskUsageInBytes: cacheDiskUsageInBytes,
                                segmentSizeInBytes: segmentSizeInBytes
                            )
                        )
                    )
                }

                task.resume()
            }
        }
    }
}
