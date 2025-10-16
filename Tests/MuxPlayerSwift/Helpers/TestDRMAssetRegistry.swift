import AVFoundation
import Foundation
@testable import MuxPlayerSwift

class TestDRMAssetRegistry : DRMAssetRegistry {
    var onDRMAsset: ((AVURLAsset, String, MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, String) -> Void)?
    func addDRMAsset(_ urlAsset: AVURLAsset, playbackID: String, options: MuxPlayerSwift.PlaybackOptions.DRMPlaybackOptions, rootDomain: String) {
        onDRMAsset?(urlAsset, playbackID, options, rootDomain)
    }
}
