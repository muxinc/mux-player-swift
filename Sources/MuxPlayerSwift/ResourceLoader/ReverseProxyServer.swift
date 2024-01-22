//
//  ReverseProxyServer.swift
//

import Foundation

import GCDWebServer

class ReverseProxyServer {

    var session: URLSession = .shared
    var webServer: GCDWebServer

    private let port: UInt = 1234
    let originURLKey: String = "__hls_origin_url"

    init() {
        self.webServer = GCDWebServer()
    }

    private func start() {
        guard !webServer.isRunning else {
            return
        }

        webServer.start(
            withPort: port,
            bonjourName: nil
        )
    }

    private func stop() {
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

                    let originalManifest = String(
                        data: data,
                        encoding: .utf8
                    )
                    let parsedManifest = originalManifest?
                        .components(separatedBy: .newlines)
                        .map { line in self.processPlaylistLine(line, forOriginURL: originURL) }
                        .joined(separator: "\n")


                    return completion(GCDWebServerErrorResponse(statusCode: 500))
                }

                task.resume()
            }


        }

    }

    private func processPlaylistLine(
        _ line: String,
        forOriginURL originURL: URL
    ) -> String {
        guard !line.isEmpty else { return line }

        if line.hasPrefix("#") {
            return lineByReplacingURI(line: line, forOriginURL: originURL)
        }

        if let originalSegmentURL = absoluteURL(from: line, forOriginURL: originURL),
           let reverseProxyURL = reverseProxyURL(from: originalSegmentURL) {
            return reverseProxyURL.absoluteString
        }
        return line
    }

    private func lineByReplacingURI(line: String, forOriginURL originURL: URL) -> String {
        let uriPattern = try! NSRegularExpression(pattern: "URI=\"([^\"]*)\"")
        let lineRange = NSRange(location: 0, length: line.count)
        guard let result = uriPattern.firstMatch(in: line, options: [], range: lineRange) else { return line }

        let uri = (line as NSString).substring(with: result.range(at: 1))
        guard let absoluteURL = absoluteURL(from: uri, forOriginURL: originURL) else { return line }
        guard let reverseProxyURL = reverseProxyURL(from: absoluteURL) else { return line }

        return uriPattern.stringByReplacingMatches(in: line, options: [], range: lineRange, withTemplate: "URI=\"\(reverseProxyURL.absoluteString)\"")
    }

    private func absoluteURL(from line: String, forOriginURL originURL: URL) -> URL? {
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
