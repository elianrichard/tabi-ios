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
    
    @MainActor
    static let shared = SwiftDataService()
    
    @MainActor
    private init() {
        do {
            self.modelContainer = try ModelContainer(
                //            for: NoteData.self, EventData.self, Expense.self, ExpenseItem.self, ExpensePerson.self,
                for: NoteData.self, EventData.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create the application's model container: \(error.localizedDescription)")
        }
    }
    
    func saveModelContext(){
        do {
            try modelContext.save()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
