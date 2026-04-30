//
//  OfflineAccessExampleHostingController.swift
//  MuxPlayerSwiftExample
//

import SwiftUI

/// A UIHostingController subclass so the storyboard segue can
/// instantiate this screen by class name.
final class OfflineAccessExampleHostingController: UIHostingController<OfflineAccessExampleView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: OfflineAccessExampleView())
    }
}
