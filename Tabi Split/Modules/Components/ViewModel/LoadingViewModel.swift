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

    var isLoading: Bool = false
    /// The Lottie animation to show while loading — the most recent in-flight
    /// request's choice, falling back to the default when none is set.
    var animationName: String = "LoadingComponent"

    // Track each in-flight request's animation so ending one restores the prior.
    private var animationStack: [String] = []

    func toggleIsLoading() {
        isLoading.toggle()
    }

    func beginRequest(animation: String = defaultAnimation) {
        animationStack.append(animation)
        animationName = animation
        isLoading = !animationStack.isEmpty
    }

    func endRequest() {
        if !animationStack.isEmpty {
            animationStack.removeLast()
        }
        animationName = animationStack.last ?? "LoadingComponent"
        isLoading = !animationStack.isEmpty
    }
}
