//
//  OfflineLicenseRenewalError.swift
//  MuxPlayerSwift
//

import Foundation

/// Why renewing a downloaded asset's DRM license didn't work.
@available(tvOS, unavailable, message: "Offline downloads are unavailable on tvOS.")
public enum OfflineLicenseRenewalError: Error {
    /// There's no completed download for this playback ID. Download the asset
    /// before renewing its license.
    case notDownloaded
    /// The download isn't DRM-protected, so it has no license to renew.
    case notDRMProtected
    /// A download for this playback ID is running right now, which fetches its
    /// own license. Wait for it to finish.
    case downloadInProgress
    /// The download has no content key identifier recorded, which is the case for
    /// anything downloaded before this SDK version. Re-download the asset to make
    /// it renewable.
    case keyIdentifierUnavailable
    /// The supplied `drm_token` isn't a readable JWT, or isn't signed for offline
    /// use. Renewing needs an offline token, the same as downloading does.
    case invalidDRMToken
    /// The license request itself failed, e.g. no connectivity or a token the
    /// license server rejected.
    case licenseRequestFailed(any Error)
    /// The license was renewed, but the asset couldn't be reopened afterwards.
    case assetUnavailableAfterRenewal
}
