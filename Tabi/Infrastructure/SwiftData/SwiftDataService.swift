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
        self.modelContainer = try! ModelContainer(for: EventData.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false))
        self.modelContext = modelContainer.mainContext
    }
    
    func saveModelContext(){
        do {
            try modelContext.save()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
