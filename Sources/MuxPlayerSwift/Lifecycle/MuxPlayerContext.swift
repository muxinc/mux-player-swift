import Foundation
import AVKit
import AVFoundation
import UIKit
import MUXSDKStats

// Connect a PlayerBinding to Player (and UI object, as required by the Mux Data SDK)
//  - An instance of this lives in MuxPlayerContainerViewController to manage Mux Data integration
//  - can be used as a sibling of an AVPlayerLayer to use Mux functionality in a custom player view
public class MuxPlayerContext {
    
    public let player: AVPlayer
    public var muxDataPlayerID: String? {
        get {
            return monitoringInfo?.monitoringId
        }
    }
    
    private var timeControlObservation: NSKeyValueObservation?
    private var errorObservation: NSKeyValueObservation?
    private var monitoringInfo: MonitoringInfo?
    
    @MainActor
    public func bindViewController(
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
    public func bindPlayerLayer(
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
    public func endMonitoring() {
        if let monitoringInfo = self.monitoringInfo {
            MUXSDKStats.destroyPlayer(monitoringInfo.monitoringId)
            self.monitoringInfo = nil
        }
    }
    
    public static func generateMonitoringID() -> String {
        return UUID().uuidString
    }
    
    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        // If playing or trying to play, try to set the audio session to active. If paused, don't hog it
        switch (status) {
        case .paused:
            try? AVAudioSession.sharedInstance().setActive(false)
        case .playing, .waitingToPlayAtSpecifiedRate:
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    private func handlePlayerError(_ error: Error) {
        // might change the AVPlayerItem:
        //  if we're using the proxy cache and there was a playback error then we try again with the original outside URL
        PlayerSDK.shared.handlePlayerError(self.player)
    }
    
    
    init(player: AVPlayer) {
        self.player = player;
        defer {
            self.timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, change in
                if let self, let timeControlStatus = change.newValue {
                    self.handleTimeControlStatus(timeControlStatus)
                }
            }
            self.errorObservation = player.observe(\.error, options: [.new]) { [weak self] _, change in
                if let self, let error = change.newValue, let error {
                    self.handlePlayerError(error)
                }
            }
        }
    }
    
    deinit {
        self.timeControlObservation?.invalidate()
        self.errorObservation?.invalidate()
        
        // try just in case, since we're about to clear the player item anyway
        try? AVAudioSession.sharedInstance().setActive(false)
        
        // ensure the rendering pipeline underneath is cleaned up as quickly as possible
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
