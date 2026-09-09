//
//  ShareSheet.swift
//  Tabi Split
//
//  Created by Elian Richard on 11/08/26.
//

import SwiftUI
import UIKit

/// SwiftUI wrapper around `UIActivityViewController` so an exported file (e.g. a PDF)
/// can be shared or saved from anywhere in the app.
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    /// Called when the activity controller finishes — including a plain cancel.
    /// The presenting view must use this to clear its sheet state; without it the
    /// SwiftUI sheet stays presented after a cancel and the share UI reappears.
    var onFinish: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onFinish?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}