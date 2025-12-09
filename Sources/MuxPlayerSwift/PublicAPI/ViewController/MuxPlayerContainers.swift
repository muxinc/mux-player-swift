import Foundation
import UIKit
import AVKit
import MuxCore
import MUXSDKStats

/// Contains an AVPlayerViewController, set up for monitoring by Mux
@MainActor
public class MuxPlayerContainerViewController<Player: AVPlayer> : UIViewController {
    
    public var player: Player? {
        set(value) {
            if let value {
                playerContext = MuxPlayerContext(player: value)
                playerContext?.bindViewController(playerViewController)
            } else {
                playerContext = nil
            }
        }
        get {
            return playerContext?.player
        }
    }
    public var muxDataPlayerID: String? {
        get {
            playerContext?.muxDataPlayerID
        }
    }
    public let playerViewController: AVPlayerViewController
    
    private var playerContext: MuxPlayerContext<Player>?
    
    public func updateMuxMetadata(_ data: MUXSDKCustomerData) {
        if let playerContext, let playerID = playerContext.muxDataPlayerID {
            MUXSDKStats.setCustomerData(data, forPlayer: playerID)
        }
    }
    
    convenience init() {
        self.init(muxMetadata: MUXSDKCustomerData())
    }
    
    public init(muxMetadata: MUXSDKCustomerData) {
        playerViewController = AVPlayerViewController()
        super.init()
        
        updateMuxMetadata(muxMetadata)
        addChild(playerViewController)
    }
    
    public required init?(coder: NSCoder) {
        playerViewController = AVPlayerViewController()
        super.init(coder: coder)
        
        addChild(playerViewController)
    }
}
