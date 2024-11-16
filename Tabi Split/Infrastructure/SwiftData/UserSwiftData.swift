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
                var image: String? = user.userImage
                if user.userImage == "" {
                    image = nil
                }
                let newUser = UserData(name: user.userName, phone: user.userPhone, image: ProfileImageEnum(rawValue: user.userImage), imageUrl: image)
                modelContext.insert(newUser)
            }
        }
    }
    
    func getCurrentUser () -> UserData? {
        if let users = fetchAllUser(), let currentUser = UserDefaultsService.shared.getCurrentUser() {
            return users.first(where: { $0.phone == currentUser.userPhone })
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
}
