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
    /// Language codes for subtitles (e.g., 'en' or 'en-US')
    public let subtitleLanguages: [String]?
    /// Language codes for secondary audio tracks (e.g., 'en' or 'en-US')
    public let secondaryAudioLanguages: [String]?
    
    public init(readableTitle: String) {
        self.readableTitle = readableTitle
        
        self.posterData = nil
        self.subtitleLanguages = nil
        self.secondaryAudioLanguages = nil
    }
}
