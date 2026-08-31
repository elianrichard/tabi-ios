//
//  SessionState.swift
//  Tabi Split
//
//  Shared transient session-level UI state.
//

import Foundation

@Observable
@MainActor
final class SessionState {
    static let shared = SessionState()

    var sessionExpiredBanner: Bool = false
    var migrationRunning: Bool = false
    var lastMigrationError: String?

    /// Drives ContentView's root view. Setting this true (after login/register)
    /// swaps the NavigationStack root to HomeView, so the auth screens are no
    /// longer on the stack and Back cannot return to them.
    var isAuthenticated: Bool = false

    private init() {}
}
