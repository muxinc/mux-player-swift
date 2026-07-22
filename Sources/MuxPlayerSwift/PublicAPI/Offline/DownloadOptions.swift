//
//  DownloadOptions.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation

/// Options for configuring a download
@available(tvOS, unavailable, message: "Offline downloads are unavailable on tvOS.")
public struct DownloadOptions {
    /// A human-readable title for the download
    public let readableTitle: String
    /// Optional poster image data
    public let posterData: Data?
    
    public init(
        readableTitle: String,
        posterData: Data? = nil
    ) {
        self.readableTitle = readableTitle
        self.posterData = posterData
    }
}
