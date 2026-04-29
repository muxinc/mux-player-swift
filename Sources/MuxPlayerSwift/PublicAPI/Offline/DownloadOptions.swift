//
//  DownloadOptions.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation

/// Options for configuring a download
public struct DownloadOptions {
    /// A human-readable title for the download
    public let readableTitle: String
    /// Optional poster image data
    public let posterData: Data?
    /// Media selection policy for audio and subtitle tracks.
    public let mediaSelectionPolicy: OfflineMediaSelectionPolicy
    
    public init(
        readableTitle: String,
        posterData: Data? = nil,
        mediaSelectionPolicy: OfflineMediaSelectionPolicy = .automatic
    ) {
        self.readableTitle = readableTitle
        self.posterData = posterData
        self.mediaSelectionPolicy = mediaSelectionPolicy
    }
}
