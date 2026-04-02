//
//  OfflineAccessExampleViewController.swift
//  MuxPlayerSwiftExample
//
//  Created by Emily Dixon on 2/25/26.
//

import Foundation
import UIKit
import AVKit
import MuxPlayerSwift
import Combine

// MARK: - Main View Controller

class OfflineAccessExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // In your app, this would probably come from your app's backend or CMS
    let examplePlaybackOptions: [ExampleAsset] = [
        ExampleAsset(
            playbackID: "zyII9g3ndjv9jOQi7JQh37oAUfLok2kvtdHmlGBPuVc",
            title: "Tears of Steel"
        ),
        ExampleAsset(
            playbackID: "fjE8FXeoV53XONhWPlQp3yl98iv8k02gtj6jvBvKovVo",
            title: "Elephant's Dream"
        ),
        ExampleAsset(
            playbackID: "Q3ikJX28joohwD02j01Ew7yyPYeraJwRjVVXrwZjt9xUo",
            title: "Making of Sintel"
        ),
        ExampleAsset(
            playbackID: "01dsHZ81nZSCx3vVfb1jnzQPC1ZjEQ002w8gfddqxNd9k",
            title: "Sintel"
        ),
        ExampleAsset(
            playbackID: "zrQ02TP4Br02KycnnAJIM8FPnohUZLZprkDC33nWzJavc",
            title: "SF Video Tech Talk"
        )
    ]
    
    // Track download states by playback ID
    private var downloadStates: [String: AssetDownloadState] = [:]
    /// One subscription per playback ID; removed when the download finishes, fails, or is cancelled so we do not retain completed sinks indefinitely.
    private var downloadSubscriptions: [String: AnyCancellable] = [:]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Offline Assets"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DownloadAssetCell.self, forCellReuseIdentifier: "DownloadAssetCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CTACell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadExistingDownloads()
    }
    
    // MARK: - Download Management
    
    private func loadExistingDownloads() {
        Task {
            // Load completed downloads
            let completedAssets = await MuxOfflineAccessManager.shared.allDownloadedAssets()
            for asset in completedAssets {
                switch asset.assetStatus {
                case .playable(let avAsset):
                    downloadStates[asset.playbackID] = .downloaded(avAsset)
                case .redownloadWhenOnline:
                    downloadStates[asset.playbackID] = .mustRedownload
                case .expired:
                    downloadStates[asset.playbackID] = .mustRedownload
                }
            }
            
            await MainActor.run {
                for (playbackID, publisher) in inProgressPublishers {
                    downloadStates[playbackID] = .downloading(progress: 0.0)
                    subscribeToDownload(playbackID: playbackID, publisher: publisher)
                }
                tableView.reloadData()
            }
        }
    }
    
    private func startDownload(for asset: ExampleAsset) {
        Task {
            let publisher = await MuxOfflineAccessManager.shared.startDownload(
                playbackID: asset.playbackID,
                playbackOptions: .init(),
                downloadOptions: DownloadOptions(readableTitle: asset.title)
            )
            
            await MainActor.run {
                downloadStates[asset.playbackID] = .downloading(progress: 0.0)
                subscribeToDownload(playbackID: asset.playbackID, publisher: publisher)
                tableView.reloadData()
            }
        }
    }
    
    @MainActor
    private func subscribeToDownload(playbackID: String, publisher: AnyPublisher<DownloadEvent, Error>) {
        downloadSubscriptions[playbackID] = publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.downloadSubscriptions.removeValue(forKey: playbackID)
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleDownloadError(error, for: playbackID)
                    }
                },
                receiveValue: { [weak self] event in
                    self?.handleDownloadEvent(event, for: playbackID)
                }
            )
    }
    
    private func handleDownloadEvent(_ event: DownloadEvent, for playbackID: String) {
        print("handleDownloadEvent: playbackID \(playbackID)")
        switch event {
        case .started:
            print("\tStarted")
            downloadStates[playbackID] = .downloading(progress: 0.0)
        case .waitingForConnectivity:
            print("\tWaiting for connectivity")
            // Keep current progress state
            break
        case .progress(let percent):
            print("\tprogress: \(percent)")
            downloadStates[playbackID] = .downloading(progress: percent)
        case .completed(let downloadedAsset):
            print("\tcompleted:")
            if let avAsset = downloadedAsset.avAssetIfPlayable() {
                downloadStates[playbackID] = .downloaded(avAsset)
            } else {
                downloadStates[playbackID] = .mustRedownload
            }
        }
        
        tableView.reloadData()
    }
    
    private func handleDownloadError(_ error: Error, for playbackID: String) {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return
        }
        
        print("\tDownload failed for \(playbackID): \(error)")
        downloadStates[playbackID] = .error(error)
        tableView.reloadData()
    }
    
    private func cancelOrDeleteDownload(for playbackID: String) {
        downloadSubscriptions.removeValue(forKey: playbackID)
        Task {
            await MuxOfflineAccessManager.shared.removeDownload(playbackID: playbackID)
            await MainActor.run {
                downloadStates.removeValue(forKey: playbackID)
                tableView.reloadData()
            }
        }
    }
    
    private func playDownloadedAsset(playbackID: String) {
        Task {
            // Get the local asset from the offline manager
            guard let localAsset = await MuxOfflineAccessManager.shared.findDownloadedAsset(playbackID: playbackID) else {
                print("Failed to get local asset for playback ID: \(playbackID)")
                return
            }
            
            if let avAsset = localAsset.avAssetIfPlayable() {
                await MainActor.run {
                    // Create player item and player from the local asset
                    let playerItem = AVPlayerItem(asset: avAsset)
                    let player = AVPlayer(playerItem: playerItem)
                    
                    // Create and configure the player container view controller
                    let playerContainerVC = MuxPlayerContainerViewController()
                    playerContainerVC.player = player
                    playerContainerVC.modalPresentationStyle = .fullScreen
                    
                    // Present the player
                    present(playerContainerVC, animated: true) {
                        player.play()
                    }
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Downloaded/Downloading assets
            return downloadStates.isEmpty ? 0 : downloadStates.count
        case 1: // CTA
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return downloadStates.isEmpty ? nil : "My Downloads"
        case 1:
            return nil
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // Downloaded/Downloading assets
            let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadAssetCell", for: indexPath) as! DownloadAssetCell
            let playbackID = Array(downloadStates.keys).sorted()[indexPath.row]
            let state = downloadStates[playbackID] ?? .notDownloaded
            let asset = examplePlaybackOptions.first { $0.playbackID == playbackID }
            
            // Configure based on state using switch
            switch state {
            case .mustRedownload, .error:
                if let asset = asset {
                    // Retry and Cancel buttons for mustRedownload and error
                    cell.configure(
                        title: asset.title,
                        state: state,
                        onAction: { [weak self] in
                            // Retry button
                            self?.startDownload(for: asset)
                        },
                        onSecondaryAction: { [weak self] in
                            // Cancel button
                            self?.cancelOrDeleteDownload(for: playbackID)
                        }
                    )
                } else {
                    // Fallback when asset metadata isn't found
                    cell.configure(
                        title: "Unknown Asset",
                        state: state,
                        onAction: { [weak self] in
                            self?.cancelOrDeleteDownload(for: playbackID)
                        }
                    )
                }
            case .downloaded:
                cell.configure(
                    title: asset?.title ?? "Unknown Asset",
                    state: state,
                    onAction: { [weak self] in
                        self?.cancelOrDeleteDownload(for: playbackID)
                    }
                )
                cell.accessoryType = .disclosureIndicator
            case .downloading, .notDownloaded:
                cell.configure(
                    title: asset?.title ?? "Unknown Asset",
                    state: state,
                    onAction: { [weak self] in
                        self?.cancelOrDeleteDownload(for: playbackID)
                    }
                )
                cell.accessoryType = .none
            }
            
            return cell
            
        case 1: // CTA
            let cell = tableView.dequeueReusableCell(withIdentifier: "CTACell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = "Download New Asset"
            content.image = UIImage(systemName: "plus.circle.fill")
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        default:
            return UITableViewCell()
        }
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 { // Downloaded/Downloading asset tapped
            let playbackID = Array(downloadStates.keys).sorted()[indexPath.row]
            let state = downloadStates[playbackID] ?? .notDownloaded
            
            // Only play if the asset is fully downloaded
            if case .downloaded = state {
                playDownloadedAsset(playbackID: playbackID)
            }
        } else if indexPath.section == 1 { // CTA tapped
            let selectionVC = AssetSelectionViewController(
                assets: examplePlaybackOptions,
                onAssetSelected: { [weak self] asset in
                    self?.startDownload(for: asset)
                }
            )
            navigationController?.pushViewController(selectionVC, animated: true)
        }
    }
}

// MARK: - Asset Selection View Controller

class AssetSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let assets: [ExampleAsset]
    private let onAssetSelected: (ExampleAsset) -> Void
    
    init(assets: [ExampleAsset], onAssetSelected: @escaping (ExampleAsset) -> Void) {
        self.assets = assets
        self.onAssetSelected = onAssetSelected
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Asset to Download"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AssetCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell", for: indexPath)
        let asset = assets[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = asset.title
        content.secondaryText = asset.playbackID
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let asset = assets[indexPath.row]
        onAssetSelected(asset)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Custom Cell

class DownloadAssetCell: UITableViewCell {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private let actionButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    private let secondaryActionButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    private var onAction: (() -> Void)?
    private var onSecondaryAction: (() -> Void)?
    
    private var titleTrailingToSecondaryConstraint: NSLayoutConstraint!
    private var titleTrailingToActionConstraint: NSLayoutConstraint!
    private var titleTrailingToContentConstraint: NSLayoutConstraint!
    private var actionTrailingConstraint: NSLayoutConstraint!
    private var secondaryToActionConstraint: NSLayoutConstraint!
    private var actionWidthConstraint: NSLayoutConstraint!
    private var secondaryWidthConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(actionButton)
        contentView.addSubview(secondaryActionButton)
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        secondaryActionButton.addTarget(self, action: #selector(secondaryActionButtonTapped), for: .touchUpInside)
        
        // Constraints
        actionTrailingConstraint = actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        secondaryToActionConstraint = secondaryActionButton.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -8)
        
        titleTrailingToSecondaryConstraint = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: secondaryActionButton.leadingAnchor, constant: -12)
        titleTrailingToActionConstraint = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -12)
        titleTrailingToContentConstraint = titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        actionWidthConstraint = actionButton.widthAnchor.constraint(equalToConstant: 0)
        secondaryWidthConstraint = secondaryActionButton.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            // Icon on the left
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Pin action button to trailing edge first (right-justified)
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionTrailingConstraint,
            
            // Secondary action button goes to the left of action button
            secondaryActionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            secondaryToActionConstraint,
            
            // Labels fill the space between icon and buttons
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        // Default: let title expand to content trailing; collapse both buttons until configured
        titleTrailingToContentConstraint.isActive = true
        titleTrailingToActionConstraint.isActive = false
        titleTrailingToSecondaryConstraint.isActive = false
        
        actionWidthConstraint.isActive = true
        secondaryWidthConstraint.isActive = true
    }
    
    func configure(
        title: String,
        state: AssetDownloadState,
        onAction: @escaping () -> Void,
        onSecondaryAction: (() -> Void)? = nil
    ) {
        self.titleLabel.text = title
        self.onAction = onAction
        self.onSecondaryAction = onSecondaryAction
        
        switch state {
        case .notDownloaded:
            statusLabel.text = "Not Downloaded"
            statusLabel.isHidden = false
            progressView.isHidden = true
            
            // Collapse both buttons and let labels extend to trailing
            actionButton.isHidden = true
            actionWidthConstraint.isActive = true
            secondaryActionButton.isHidden = true
            secondaryWidthConstraint.isActive = true
            
            titleTrailingToContentConstraint.isActive = true
            titleTrailingToActionConstraint.isActive = false
            titleTrailingToSecondaryConstraint.isActive = false
            
            iconImageView.isHidden = true
            
        case .downloading(let progress):
            statusLabel.text = "Downloading... \(Int(progress))%"
            statusLabel.isHidden = false
            progressView.isHidden = false
            progressView.progress = Float(progress / 100.0)
            // Show primary action, hide secondary; constrain labels to action button
            actionButton.isHidden = false
            actionWidthConstraint.isActive = false
            secondaryActionButton.isHidden = true
            secondaryWidthConstraint.isActive = true
            
            titleTrailingToContentConstraint.isActive = false
            titleTrailingToActionConstraint.isActive = true
            titleTrailingToSecondaryConstraint.isActive = false
            
            actionButton.configuration?.attributedTitle = AttributedString("Cancel", attributes: AttributeContainer([.foregroundColor: UIColor.systemRed]))
            iconImageView.image = UIImage(systemName: "arrow.down.circle")
            iconImageView.tintColor = .systemBlue
            iconImageView.isHidden = false
            
        case .downloaded:
            statusLabel.text = "Downloaded"
            statusLabel.isHidden = false
            progressView.isHidden = true
            // Show primary action, hide secondary; constrain labels to action button
            actionButton.isHidden = false
            actionWidthConstraint.isActive = false
            secondaryActionButton.isHidden = true
            secondaryWidthConstraint.isActive = true
            
            titleTrailingToContentConstraint.isActive = false
            titleTrailingToActionConstraint.isActive = true
            titleTrailingToSecondaryConstraint.isActive = false
            
            actionButton.configuration?.attributedTitle = AttributedString("Delete", attributes: AttributeContainer([.foregroundColor: UIColor.systemRed]))
            iconImageView.image = UIImage(systemName: "play.circle.fill")
            iconImageView.tintColor = .systemBlue
            iconImageView.isHidden = false
            
        case .mustRedownload:
            statusLabel.text = "Must Redownload"
            statusLabel.isHidden = false
            progressView.isHidden = true
            // Show both buttons; constrain labels to secondary button
            actionButton.isHidden = false
            actionWidthConstraint.isActive = false
            secondaryActionButton.isHidden = false
            secondaryWidthConstraint.isActive = false
            
            titleTrailingToContentConstraint.isActive = false
            titleTrailingToActionConstraint.isActive = false
            titleTrailingToSecondaryConstraint.isActive = true
            
            actionButton.configuration?.attributedTitle = AttributedString("Retry", attributes: AttributeContainer([.foregroundColor: UIColor.systemBlue]))
            secondaryActionButton.configuration?.attributedTitle = AttributedString("Cancel", attributes: AttributeContainer([.foregroundColor: UIColor.systemRed]))
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            iconImageView.tintColor = .systemOrange
            iconImageView.isHidden = false
            
        case .error(let error):
            statusLabel.text = error.localizedDescription
            statusLabel.isHidden = false
            progressView.isHidden = true
            // Show both buttons; constrain labels to secondary button
            actionButton.isHidden = false
            actionWidthConstraint.isActive = false
            secondaryActionButton.isHidden = false
            secondaryWidthConstraint.isActive = false
            
            titleTrailingToContentConstraint.isActive = false
            titleTrailingToActionConstraint.isActive = false
            titleTrailingToSecondaryConstraint.isActive = true
            
            actionButton.configuration?.attributedTitle = AttributedString("Retry", attributes: AttributeContainer([.foregroundColor: UIColor.systemBlue]))
            secondaryActionButton.configuration?.attributedTitle = AttributedString("Cancel", attributes: AttributeContainer([.foregroundColor: UIColor.systemRed]))
            iconImageView.image = UIImage(systemName: "exclamationmark.circle.fill")
            iconImageView.tintColor = .systemRed
            iconImageView.isHidden = false
        }
    }
    
    @objc private func actionButtonTapped() {
        onAction?()
    }
    
    @objc private func secondaryActionButtonTapped() {
        onSecondaryAction?()
    }
}

// MARK: - Supporting Types

enum AssetDownloadState {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(AVURLAsset)
    case mustRedownload
    case error(Error)
}

struct ExampleAsset {
    let playbackID: String
    let title: String
    let languages: String? = nil
    
    let playbackToken: String? = nil
    let drmToken: String? = nil
}

