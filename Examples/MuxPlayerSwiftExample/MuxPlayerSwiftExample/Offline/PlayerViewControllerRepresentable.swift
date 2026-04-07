//
//  PlayerViewControllerRepresentable.swift
//  MuxPlayerSwiftExample
//
//  Created by Emily Dixon on 4/7/26.
//

import AVFoundation
import SwiftUI
import UIKit
import MuxPlayerSwift

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> MuxPlayerContainerViewController {
        let controller = MuxPlayerContainerViewController()
        return controller
    }

    func updateUIViewController(_ uiViewController: MuxPlayerContainerViewController, context: Context) {
        guard uiViewController.player !== player else { return }
        uiViewController.player = player
        player.play()
    }
}
