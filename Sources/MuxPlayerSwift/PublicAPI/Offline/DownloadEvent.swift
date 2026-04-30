//
//  DownloadEvent.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation

/// Events emitted during a download
public enum DownloadEvent {
    /// The download has started
    case started
    /// The download is waiting for network connectivity
    case waitingForConnectivity
    /// Progress update with percentage complete
    case progress(percent: Double)
    /// The download has completed successfully
    case completed(DownloadedAsset)
}
