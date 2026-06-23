import AVFoundation
import Foundation
@testable import MuxPlayerSwift

class TestDRMAssetRegistry : DRMAssetRegistry {
    func addOfflineDownloadDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
    }
    
    func removeOfflineDownloadSession(playbackID: String) {
    }
    
    func addOfflinePlayDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, keyData: Data) async {
    }
    
    /// When true, `hasOfflineDRMConfig` reports the asset as offline (download /
    /// offline playback). Defaults to false (online), matching most tests.
    var offlineConfigured: Bool = false
    /// The `drm_token` reported for online assets, used for cache fingerprinting.
    var onlineToken: String?
    /// The root domain reported for online assets.
    var onlineRootDomain: String = "mux.com"

    func hasOfflineDRMConfig(playbackID: String) async -> Bool {
        return offlineConfigured
    }

    func offlineKeyData(playbackID: String) async -> Data? {
        return nil
    }

    func onlineDRMCredentials(playbackID: String) async -> (drmToken: String, rootDomain: String)? {
        guard let onlineToken else { return nil }
        return (onlineToken, onlineRootDomain)
    }

    var onDRMAsset: ((AVURLAsset, String, MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, String) -> Void)?
    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
        onDRMAsset?(urlAsset, playbackID, options, rootDomain)
    }
}
