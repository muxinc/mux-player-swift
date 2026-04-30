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
    
    func hasOfflineDRMConfig(playbackID: String) async -> Bool {
        return false
    }
    
    func offlineKeyData(playbackID: String) async -> Data? {
        return nil
    }
    
    var onDRMAsset: ((AVURLAsset, String, MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, String) -> Void)?
    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
        onDRMAsset?(urlAsset, playbackID, options, rootDomain)
    }
}
