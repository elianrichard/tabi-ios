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

    private init() {}
}
