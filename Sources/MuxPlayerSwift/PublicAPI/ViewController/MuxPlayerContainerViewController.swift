import Foundation
import UIKit
import AVKit
import MuxCore
import MUXSDKStats

//typealias MuxAVQueuePlayerViewController = MuxPlayerContainerViewController<AVQueuePlayer>
//typealias MuxAVPlayerViewController = MuxPlayerContainerViewController<AVPlayer>


/// Contains an AVPlayerViewController, set up for monitoring by Mux.
///  To set PlaybackParams, use ``AVKit/AVPlayerItem/init(playbackID:playbackOptions:)``
@MainActor
public class MuxPlayerContainerViewController : UIViewController {
    
    public var player: AVPlayer? {
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
    
    private var playerContext: MuxPlayerContext?
    
    public func updateMuxMetadata(_ data: MUXSDKCustomerData) {
        if let playerContext, let playerID = playerContext.muxDataPlayerID {
            MUXSDKStats.setCustomerData(data, forPlayer: playerID)
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        addPlayerVCAsChild()
    }
    
    private func addPlayerVCAsChild() {
        addChild(self.playerViewController)
        view.addSubview(self.playerViewController.view)
        self.playerViewController.view.frame = self.view.bounds
        self.playerViewController.didMove(toParent: self)
    }
    
    convenience init() {
        self.init(muxMetadata: MUXSDKCustomerData())
    }
    
    public init(muxMetadata: MUXSDKCustomerData) {
        self.playerViewController = AVPlayerViewController()
        super.init()
        
        updateMuxMetadata(muxMetadata)
    }
    
    public required init?(coder: NSCoder) {
        self.playerViewController = AVPlayerViewController()
        super.init(coder: coder)
    }
}
