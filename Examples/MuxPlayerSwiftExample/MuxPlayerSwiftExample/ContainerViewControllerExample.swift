//
//  ContainerViewControllerExample.swift
//  MuxPlayerSwiftExample
//
//  Created by Emily Dixon on 12/9/25.
//

import AVKit
import UIKit
import MuxPlayerSwift

class ContainerViewControllerExample : UIViewController {
    
    private var playerViewController: MuxPlayerContainerViewController?
    private var player: AVPlayer?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedPlayerVC", let destinationViewController = segue.destination as? MuxPlayerContainerViewController {
            self.playerViewController = destinationViewController
        }
    }
    
    override func viewDidLoad() {
        let playerItem = AVPlayerItem(playbackID: "5ICwECLW8900gMTi5eaOkWdYvOkGhtKyBY02uRCT6FOyE")
        let player = AVPlayer(playerItem: playerItem)
        
        playerViewController?.player = player
        
        player.play()
        
        self.player = player
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
