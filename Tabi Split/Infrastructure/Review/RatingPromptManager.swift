//
//  RatingPromptManager.swift
//  Tabi Split
//
//  Decides *when* to ask for an App Store rating and signals the app root to
//  fire Apple's native prompt. StoreKit is intentionally kept out of here so the
//  cadence logic stays unit-testable; ContentView reads `pendingReview` and
//  invokes the SwiftUI `requestReview` environment action.
//
//  We use the *native* prompt only. Its 1-5★ UI is Apple's own — we never
//  pre-collect stars, never funnel by sentiment, and can't read the result or
//  know if it appeared. This keeps the feature safe under App Store guidelines
//  1.1.7 / 5.6. The OS is the final throttle (~3 shows / 365 days / device).
//

import Foundation

@Observable
@MainActor
final class RatingPromptManager {
    static let shared = RatingPromptManager()

    // Cadence constants. See plan: ask once the user has felt real value, space
    // attempts far apart, and cap lifetime attempts at Apple's own ceiling so we
    // never waste calls fighting the OS throttle.
    private let minSuccesses = 3
    private let cooldownDays = 60
    private let maxLifetimeRequests = 3

    private let defaults: UserDefaultsService
    private let now: () -> Date

    // Flipped true when a native prompt should fire. ContentView observes this,
    // calls the requestReview env action, and resets it to false.
    var pendingReview = false

    // Injectable seams keep `shouldRequestReview()` testable without touching
    // global UserDefaults or the real clock.
    init(defaults: UserDefaultsService = .shared, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
    }

    /// Call after a successful expense *create* (not edit). Always counts the
    /// success; fires the native prompt only when the cadence allows.
    func registerSuccessfulExpense() {
        defaults.incrementRatingSuccessCount()

        guard shouldRequestReview() else { return }

        // Record the attempt up front so a crash mid-prompt still counts against
        // the cooldown and lifetime cap.
        defaults.setRatingLastRequestedAt(now())
        defaults.incrementRatingRequestCount()
        pendingReview = true
    }

    func shouldRequestReview() -> Bool {
        if defaults.getRatingRequestCount() >= maxLifetimeRequests { return false }
        if defaults.getRatingSuccessCount() < minSuccesses { return false }
        if let last = defaults.getRatingLastRequestedAt() {
            let elapsedDays = now().timeIntervalSince(last) / 86_400
            if elapsedDays < Double(cooldownDays) { return false }
        }
        return true
    }
}
