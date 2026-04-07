//
//  AssetDownloadState.swift
//  MuxPlayerSwiftExample
//

import AVFoundation

enum AssetDownloadState {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(AVURLAsset)
    case mustRedownload
    case error(Error)
}
