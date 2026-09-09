//
//  LoadingViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 11/12/24.
//

import SwiftUI

@Observable
@MainActor
final class LoadingViewModel {
    static let shared = LoadingViewModel()

    /// Default loading animation. Some requests override it (e.g. receipt parsing
    /// shows the scan animation) by passing an `animation` to `beginRequest`.
    static let defaultAnimation = "LoadingComponent"
    /// Default label shown under the animation; requests may override it the same way.
    static let defaultMessage = "Loading…"

    var isLoading: Bool = false
    /// The Lottie animation to show while loading — the most recent in-flight
    /// request's choice, falling back to the default when none is set.
    var animationName: String = defaultAnimation
    /// The text shown under the animation — same most-recent-request rule.
    var message: String = defaultMessage

    // Track each in-flight request's choices so ending one restores the prior.
    private var animationStack: [String] = []
    private var messageStack: [String] = []

    func toggleIsLoading() {
        isLoading.toggle()
    }

    func beginRequest(animation: String = defaultAnimation, message: String = defaultMessage) {
        animationStack.append(animation)
        messageStack.append(message)
        animationName = animation
        self.message = message
        isLoading = !animationStack.isEmpty
    }

    func endRequest() {
        if !animationStack.isEmpty {
            animationStack.removeLast()
            messageStack.removeLast()
        }
        animationName = animationStack.last ?? Self.defaultAnimation
        message = messageStack.last ?? Self.defaultMessage
        isLoading = !animationStack.isEmpty
    }
}
