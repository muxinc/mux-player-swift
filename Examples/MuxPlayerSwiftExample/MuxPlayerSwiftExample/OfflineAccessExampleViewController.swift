//
//  OfflineAccessExampleViewController.swift
//  MuxPlayerSwiftExample
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import UIKit
import MuxPlayerSwift

class OfflineAccessExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // In your app, this would probably come from your backend server
    let examplePlaybackOptions: [ExampleAsset] = [
        ExampleAsset(
            playbackID: "zyII9g3ndjv9jOQi7JQh37oAUfLok2kvtdHmlGBPuVc",
            title: "Tears of Steel"
        ),
        ExampleAsset(
            playbackID: "fjE8FXeoV53XONhWPlQp3yl98iv8k02gtj6jvBvKovVo",
            title: "Elephant's Dream"
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Offline Assets"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examplePlaybackOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let asset = examplePlaybackOptions[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = asset.title
        content.secondaryText = asset.playbackID
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Placeholder for handling selection of an asset
        // let selected = examplePlaybackOptions[indexPath.row]
    }
}

struct ExampleAsset {
    let playbackID: String
    let title: String
    let languages: String? = nil
    
    let playbackToken: String? = nil
    let drmToken: String? = nil
}

