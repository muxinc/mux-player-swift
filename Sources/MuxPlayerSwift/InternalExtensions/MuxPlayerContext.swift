import Foundation
import AVKit
import AVFoundation
import UIKit
import MUXSDKStats

// Connect a PlayerBinding to Player (and UI object, as required by Data SDK)
//  - can be used in a container VC along with a VC in order to manage there (create new context when VC player is assigned)
//  - can be used as an associated object with our extensions instead of the dictionary maze we currently have
//  - can be used with AVPlayerLayer as an inner delegate of some customer-facing object, intended to be a sibling of the AVPlayerLayer in their custom VC
//  - can be used in a SwiftUI view as a state object to contain the player/playerbinding (requires minor data sdk changes)
class MuxPlayerContext {
    
    public let player: AVPlayer
    public var muxDataPlayerID: String? {
        get {
            return monitoringInfo?.monitoringId
        }
    }
    
    private var monitoringInfo: MonitoringInfo?
    
    @MainActor
    func bindViewController(
        _ vc: AVPlayerViewController,
        playerID: String = generateMonitoringID(),
        customerData: MUXSDKCustomerData = MUXSDKCustomerData(),
        automaticErrorTracking: Bool = true
    ) {
        endMonitoring()
        vc.player = self.player
        
        let binding = MUXSDKStats.monitorAVPlayerViewController(
            vc,
            withPlayerName: playerID,
            customerData: customerData,
            automaticErrorTracking: automaticErrorTracking
        )
        
        guard let binding = binding else {
            // this is fine. will get here if self.player was nil
            return
        }
        
        self.monitoringInfo = .init(monitoringId: playerID, playerBinding: binding)
    }
    
    @MainActor
    func bindLayer(
        _ layer: AVPlayerLayer,
        playerID: String = generateMonitoringID(),
        customerData: MUXSDKCustomerData = MUXSDKCustomerData(),
        automaticErrorTracking: Bool = true
    ) {
        layer.player = self.player
        endMonitoring()
        
        let binding = MUXSDKStats.monitorAVPlayerLayer(
            layer,
            withPlayerName: playerID,
            customerData: customerData,
            automaticErrorTracking: automaticErrorTracking,
        )
        
        guard let binding = binding else {
            // this is fine. will get here if self.player was nil
            return
        }
        
        self.monitoringInfo = .init(monitoringId: playerID, playerBinding: binding)
    }
    
    
    /// end Mux Data monitoring early
    @MainActor
    func endMonitoring() {
        if let monitoringInfo = self.monitoringInfo {
            MUXSDKStats.destroyPlayer(monitoringInfo.monitoringId)
            self.monitoringInfo = nil
        }
    }
    
    private static func generateMonitoringID() -> String {
        return UUID().uuidString
    }
    
    init(player: AVPlayer) {
        self.player = player;
    }
    
    deinit {
        player.replaceCurrentItem(with: nil)
        
        // Must unbind from Mux Data on the main thread. Send playerID + binding so the rest of the object can die peacefully
        if let monitoringInfo = self.monitoringInfo {
            Task.detached { [monitoringInfo] in
                await MainActor.run { MUXSDKStats.destroyPlayer(monitoringInfo.monitoringId) }
            }
        }

        self.monitoringInfo = nil
    }
}

fileprivate struct MonitoringInfo {
    let monitoringId: String
    let playerBinding: MUXSDKPlayerBinding
}
