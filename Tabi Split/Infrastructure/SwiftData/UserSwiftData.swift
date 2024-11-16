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
    
    func saveCurrentUser (user: CurrentUserDefaults) {
        if let users = fetchAllUser() {
            if !users.contains(where: { $0.phone == user.userPhone }) {
                if let image = ProfileImageEnum(rawValue: user.userImage) {
                    modelContext.insert(UserData(name: user.userName, phone: user.userPhone, image: image, imageUrl: nil))
                } else {
                    modelContext.insert(UserData(name: user.userName, phone: user.userPhone, image: nil, imageUrl: user.userImage))
                }
                saveModelContext()
            }
        }
    }
    
    func getCurrentUser () -> UserData? {
        if let users = fetchAllUser(),
           let currentUser = UserDefaultsService.shared.getCurrentUser(),
           let user = users.first(where: { $0.phone == currentUser.userPhone }) {
            return user
        } else { return nil }
    }
    
    func editCurrentUser (name: String, phone: String, image: ProfileImageEnum.ID? = nil, imageUrl: String? = nil) {
        if let user = getCurrentUser() {
            user.name = name
            user.phone = phone
            if let image {
                user.image = image
            }
            if let imageUrl {
                user.imageUrl = imageUrl
            }
            saveModelContext()
        }
    }
    
    func deleteAllUser () {
        deleteModelContext(type: UserData.self)
    }
}
