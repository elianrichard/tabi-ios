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

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}