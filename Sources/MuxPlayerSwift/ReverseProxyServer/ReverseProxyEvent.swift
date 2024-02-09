//
//  ReverseProxyEvent.swift
//

import Foundation

struct ReverseProxyEvent: CustomStringConvertible {
    enum Kind {
        case manifestRequestReceived
        case segmentRequestReceived
        case segmentCacheMiss(
            key: URLRequest
        )
        case segmentCacheHit(
            key: URLRequest
        )
        case segmentCacheStored(
            key: URLRequest,
            cacheDiskUsageInBytes: Int,
            segmentSizeInBytes: Int
        )
    }

    let originURL: URL

    let kind: Kind

    var description: String {
        switch kind {
        case .manifestRequestReceived:
            return "Manifest Request - Origin URL: \(originURL.absoluteString)"
        case .segmentRequestReceived:
            return "Segment Request Received - Origin URL: \(originURL.absoluteString)"
        case .segmentCacheMiss(key: let key):
            return "Segment Cache Miss - Key: \(key) Origin URL: \(originURL.absoluteString)"
        case .segmentCacheHit(key: let key):
            return "Segment Cache Hit - Key: \(key) Origin URL: \(originURL.absoluteString)"
        case .segmentCacheStored(key: let key, cacheDiskUsageInBytes: let cacheDiskUsageInBytes, segmentSizeInBytes: let segmentSizeInBytes):
            return "Segment Cache Stored - Key: \(key) CacheDiskUsageInBytes: \(cacheDiskUsageInBytes) SegmentSizeInBytes: \(segmentSizeInBytes) Origin URL: \(originURL.absoluteString)"
        }
    }

}
