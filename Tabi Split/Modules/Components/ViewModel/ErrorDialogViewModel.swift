//
//  ErrorDialogViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 31/08/26.
//

import SwiftUI

// Global presenter for blocking error dialogs. Unlike the toast (transient,
// auto-dismissing, used for success/info), an error demands acknowledgment, so it
// stays until the user taps OK.
@Observable
@MainActor
final class ErrorDialogViewModel {
    static let shared = ErrorDialogViewModel()

    var message: String?

    var isPresented: Bool {
        message != nil
    }

    func show(_ message: String) {
        self.message = message
    }

    func dismiss() {
        message = nil
    }
}
