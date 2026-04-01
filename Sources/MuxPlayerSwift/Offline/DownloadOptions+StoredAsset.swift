//
//  DownloadOptions+StoredAsset.swift
//  MuxPlayerSwift
//
//  Created by Emily Dixon on 3/31/26.
//
import Foundation

extension DownloadOptions {
    init(from storedAsset: StoredAsset) {
        self.readableTitle = storedAsset.readableTitle
        
        // Decode base64 string to Data
        if let posterData = storedAsset.posterDataBase64, !posterData.isEmpty {
            self.posterData = Data(base64Encoded: posterData)
        } else {
            self.posterData = nil
        }
        
        self.subtitleLanguages = storedAsset.subtitleLanguages
        self.secondaryAudioLanguages = storedAsset.secondaryAudioLanguages
    }
}
