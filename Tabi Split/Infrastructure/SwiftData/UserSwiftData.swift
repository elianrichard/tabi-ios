//
//  UserSwiftData.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

import Foundation
import SwiftData

extension SwiftDataService {
    func fetchAllUser () -> [UserData]? {
        let fetchDescriptor = FetchDescriptor<UserData>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
