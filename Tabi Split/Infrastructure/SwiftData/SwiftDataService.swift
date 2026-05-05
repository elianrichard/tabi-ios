//
//  SwiftData.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.tabi.split", category: "SwiftData")

class SwiftDataService {
    public let modelContainer: ModelContainer
    public let modelContext: ModelContext

    @MainActor
    static let shared = SwiftDataService()

    @MainActor
    private init() {
        do {
            self.modelContainer = try ModelContainer(
                for: NoteData.self, EventData.self, UserData.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            self.modelContext = modelContainer.mainContext
        } catch {
            // ModelContainer creation is non-recoverable at launch; re-throw as a crash with context.
            preconditionFailure("Failed to create ModelContainer: \(error)")
        }
    }

    @MainActor
    func saveModelContext() {
        do {
            try modelContext.save()
        } catch {
            logger.error("SwiftData save failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func deleteModelContext<T: PersistentModel>(type: T.Type) {
        do {
            try modelContext.delete(model: T.self)
            saveModelContext()
        } catch {
            logger.error("SwiftData delete(\(String(describing: T.self))) failed: \(error.localizedDescription)")
        }
    }
}
