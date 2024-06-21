//
//  MainViewController.swift
//  MuxPlayerSwiftExample
//

import AVFoundation
import AVKit
import SwiftUI
import UIKit

import MuxPlayerSwift

class MainViewController: UIViewController {

//    lazy var playerViewController = AVPlayerViewController(
//        playbackID: playbackID
//    )
    let videoIdx = 0
    lazy var playerViewController = AVPlayerViewController(
        playbackID: "fPHwnrNKTqTdZTX00xmbbs316CauXMg02KJKZlpaxNKmc",
        playbackOptions: PlaybackOptions(
            playbackToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ2IiwiZXhwIjoxNzI2MTYyMTMwLCJraWQiOiJucFI2TFZHSjVMZG5pdXNzVzAwSEJHcHhzbElNVGVpSzhiaHI4Z0U2VHNtdyIsInN1YiI6ImZQSHduck5LVHFUZFpUWDAweG1iYnMzMTZDYXVYTWcwMktKS1pscGF4TkttYyJ9.TDP-unjybwwTQJnSoYGwpNH-_lGM1-uhCdGIWYtS3XAyekSvhQYKQBiTMF435_31vIAVQ5H2rkyQvGA6CajZWgAWe_c9_ZuPB9CJ9SEvvGZmw8bj-k1H7vFzFA_dGhWIhnhi9eW1wl_w3EsxRwZP9BRrhLec8QZGN-JAvv-upPMFTXOo1O8DNg_pag9c0u0h609YwIcBcpvBrhZDAxied_xr7GpZuZaB7SY65gx0jSuYO4S1Wp5BgWJ3jSTRFSP2jPvNHxXr-VFoCKKnAZ5v9mV6pmRZ17A-U3IsL1tsRYkLC4toIrz24sdmaPIIj3-s1E2-5g3irRujtyxJTsUaTw",
            drmToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsIiwiZXhwIjoxNzI2MTYyMTMzLCJraWQiOiJucFI2TFZHSjVMZG5pdXNzVzAwSEJHcHhzbElNVGVpSzhiaHI4Z0U2VHNtdyIsInN1YiI6ImZQSHduck5LVHFUZFpUWDAweG1iYnMzMTZDYXVYTWcwMktKS1pscGF4TkttYyJ9.OE06Sg79FagTAAho9fz-g0Jd6OexCrrey8j9v0ETo3UQ1wmawKPC95-3VJkT-qkvXgPaaApDmDS2c5ormiPZxAH3fO_nPDh8oVDGHQgnLXtKKCsL4j9jd2whBEoIpHYnjUnrp4pt1klJqGljN1LqUVYsecpXlh3JUPBjcoRW1eGuAdqbW4kfQpq7c-rZRLCs4WtFm8fSh8UamBLrvULJzgXGQmX1UlzIuN2Y_u-AxuO9VCKaSfLKobko2j9ozQ3VdnEqsThv3iQORCZHmuq4sxSwOyNLMidGcbiPGayJHDm31iG4mipdMzhICb22uCwZDEnEkT7TC08FSMMx1CZHWw"
        )
    )

//    var playbackID: String = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        
        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)

        playerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            playerViewController.view.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            playerViewController.view.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            playerViewController.view.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            playerViewController.view.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            playerViewController.view.layoutMarginsGuide.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            playerViewController.view.layoutMarginsGuide.bottomAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        let player = playerViewController.player
        let item = playerViewController.player?.currentItem
        
        playerViewController.player?.currentItem?.observe(\AVPlayerItem.status, options: [.new]) { object, change in
            print("Player Item Status: \(change.newValue)")
            if case .failed = change.newValue {
                print("!!AVPlayer Error!!")
                let error = object.error
                print(error!.localizedDescription)
            }
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        playerViewController.player?.pause()
        playerViewController.stopMonitoring()
        super.viewWillDisappear(animated)
    }

}
