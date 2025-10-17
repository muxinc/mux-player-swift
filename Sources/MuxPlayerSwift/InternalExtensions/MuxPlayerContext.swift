import Foundation
import AVKit
import AVFoundation
import UIKit
import MUXSDKStats

// TODO: Should this be an actor? that provides isolation, but makes it annoying to access the player. @MainActor might be enough since AVPlayer is also annotated that way
// purpose of this class is to manage player binding and DRM connection
//  - can be used in a container VC along with a VC in order to manage there (create new context when VC player is assigned)
//  - can be used as an associated object with our extensions instead of the dictionary maze we currently have
//  - (in the future, when VC/View no longer needed) can be used in a SwiftUI view as a state object to contain the player
class MuxPlayerContext {
    // TOOD: Wait make this optional and need to unbind() whenever this is cleared
    public let player: AVPlayer
    
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
        // TODO: start monitoring, but don't hold a reference to the view
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
    func endMonitoring() {
        if let monitoringInfo = self.monitoringInfo {
            MUXSDKStats.destroyPlayer(monitoringInfo.monitoringId)
            self.monitoringInfo = nil
        }
    }
    
    func unbind() {
        endMonitoring()
        // TODO: Remove Asset from DRM Session if present
        player.replaceCurrentItem(with: nil)
    }
    
    private static func generateMonitoringID() -> String {
        return UUID().uuidString
    }
    
    init(player: AVPlayer) {
        self.player = player;
        
        // TODO: Observe Player for PlayerItem changes? Then you're subject to notification ordering and stuff, but maybe doesn't matter
        //  we need the player item to restart playback after a media services reset and in unbind()
    }
    
    deinit {
        unbind()
    }
}

fileprivate struct MonitoringInfo {
    let monitoringId: String
    let playerBinding: MUXSDKPlayerBinding
}
