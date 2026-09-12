//
//  SwiftData.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation
import SwiftData

class SwiftDataService {
    public let modelContainer: ModelContainer
    public let modelContext: ModelContext
    /// How the store was loaded this launch (see `TabiSchema.LoadResult`).
    public let loadResult: TabiSchema.LoadResult
    private var recoveryNoticePending: Bool

    @MainActor
    static let shared = SwiftDataService()

    @MainActor
    private init() {
        // Never fatalError here: a store that cannot be migrated is moved aside and
        // recreated (the store is a server mirror). TabiApp shares this container.
        let (container, result) = TabiSchema.loadOrRecover()
        self.modelContainer = container
        self.modelContext = container.mainContext
        self.loadResult = result
        self.recoveryNoticePending = result != .opened
    }

    /// True exactly once per launch if the store had to be recreated, so the UI
    /// can tell the user their local data was reset and is reloading.
    func consumeRecoveryNotice() -> Bool {
        defer { recoveryNoticePending = false }
        return recoveryNoticePending
    }

    @discardableResult
    func saveModelContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            TabiSchema.log.error("save failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    func deleteModelContext<T: PersistentModel>(type: T.Type) {
        do {
            try modelContext.delete(model: T.self)
            saveModelContext()
        } catch {
            TabiSchema.log.error("delete all \(String(describing: T.self), privacy: .public) failed: \(String(describing: error), privacy: .public)")
        }
    }
}
