//
//  DRMExampleViewController.swift
//  MuxPlayerSwiftExample
//

import AVKit
import UIKit

import MuxPlayerSwift

class DRMExampleViewController: UIViewController {

    // MARK: Player View Controller

    lazy var playerViewController = AVPlayerViewController(
        playbackID: "fPHwnrNKTqTdZTX00xmbbs316CauXMg02KJKZlpaxNKmc",
        playbackOptions: PlaybackOptions(
            playbackToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ2IiwiZXhwIjoxNzI2MTYyMTMwLCJraWQiOiJucFI2TFZHSjVMZG5pdXNzVzAwSEJHcHhzbElNVGVpSzhiaHI4Z0U2VHNtdyIsInN1YiI6ImZQSHduck5LVHFUZFpUWDAweG1iYnMzMTZDYXVYTWcwMktKS1pscGF4TkttYyJ9.TDP-unjybwwTQJnSoYGwpNH-_lGM1-uhCdGIWYtS3XAyekSvhQYKQBiTMF435_31vIAVQ5H2rkyQvGA6CajZWgAWe_c9_ZuPB9CJ9SEvvGZmw8bj-k1H7vFzFA_dGhWIhnhi9eW1wl_w3EsxRwZP9BRrhLec8QZGN-JAvv-upPMFTXOo1O8DNg_pag9c0u0h609YwIcBcpvBrhZDAxied_xr7GpZuZaB7SY65gx0jSuYO4S1Wp5BgWJ3jSTRFSP2jPvNHxXr-VFoCKKnAZ5v9mV6pmRZ17A-U3IsL1tsRYkLC4toIrz24sdmaPIIj3-s1E2-5g3irRujtyxJTsUaTw",
            drmToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsIiwiZXhwIjoxNzI2MTYyMTMzLCJraWQiOiJucFI2TFZHSjVMZG5pdXNzVzAwSEJHcHhzbElNVGVpSzhiaHI4Z0U2VHNtdyIsInN1YiI6ImZQSHduck5LVHFUZFpUWDAweG1iYnMzMTZDYXVYTWcwMktKS1pscGF4TkttYyJ9.OE06Sg79FagTAAho9fz-g0Jd6OexCrrey8j9v0ETo3UQ1wmawKPC95-3VJkT-qkvXgPaaApDmDS2c5ormiPZxAH3fO_nPDh8oVDGHQgnLXtKKCsL4j9jd2whBEoIpHYnjUnrp4pt1klJqGljN1LqUVYsecpXlh3JUPBjcoRW1eGuAdqbW4kfQpq7c-rZRLCs4WtFm8fSh8UamBLrvULJzgXGQmX1UlzIuN2Y_u-AxuO9VCKaSfLKobko2j9ozQ3VdnEqsThv3iQORCZHmuq4sxSwOyNLMidGcbiPGayJHDm31iG4mipdMzhICb22uCwZDEnEkT7TC08FSMMx1CZHWw",
            customDomain: customDomain
        )
    )

    // MARK: Mux Data Monitoring Parameters

    var playerName: String = "MuxPlayerSwift-DRMExample"

    var environmentKey: String? {
        ProcessInfo.processInfo.environmentKey
    }

    // MARK: Mux Video Playback Parameters

    var playbackID: String {
        ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
    }

    // TODO: Display error alert if ProcessInfo returns nil
    var playbackToken: String {
        ProcessInfo.processInfo.playbackToken ?? ""
    }

    // TODO: Display error alert if ProcessInfo returns nil
    var drmToken: String {
        ProcessInfo.processInfo.drmToken ?? ""
    }

    // TODO: Display error alert if ProcessInfo returns nil
    var customDomain: String {
        ProcessInfo.processInfo.customDomain ?? ""
    }

    // MARK: Status Bar Appearance

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        displayPlayerViewController()
    }

    // MARK: Player Lifecycle

    func displayPlayerViewController() {
        playerViewController.willMove(toParent: self)
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
        playerViewController
            .view
            .translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            playerViewController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            playerViewController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            playerViewController.view.layoutMarginsGuide.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            playerViewController.view.layoutMarginsGuide.bottomAnchor
                .constraint(equalTo: view.bottomAnchor),
        ])
    }

    func hidePlayerViewController() {
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }

}
