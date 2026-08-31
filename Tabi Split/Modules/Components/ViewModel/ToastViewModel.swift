//
//  ToastViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 24/08/26.
//

import SwiftUI

enum ToastStyle {
    case error
    case success
    case info
}

@Observable
@MainActor
final class ToastViewModel {
    static let shared = ToastViewModel()

    var message: String?
    var style: ToastStyle = .error

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, style: ToastStyle = .error, duration: TimeInterval = 3.5) {
        self.message = message
        self.style = style

        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func showError(_ message: String) {
        show(message, style: .error)
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        message = nil
    }
}
