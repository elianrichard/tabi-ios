//
//  UserSwiftData.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

import Foundation
import SwiftData
import Contacts

extension SwiftDataService {
    func getAllUsers (excludeLoggedUser: Bool = false) -> [UserData]? {
        let fetchDescriptor = FetchDescriptor<UserData>()
        do {
            let users = try modelContext.fetch(fetchDescriptor)
            if let currentUser = UserDefaultsService.shared.getCurrentUser(),
               excludeLoggedUser {
                return users.filter{ $0.phone != currentUser.userPhone }
            } else { return users }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func deleteUsersWithNoId () {
        if let users = getAllUsers() {
            for user in users {
                if user.userId == "" {
                    modelContext.delete(user)
                }
            }
        }
    }
    
    func saveCurrentUser (user: CurrentUserDefaults) {
        if let users = getAllUsers() {
            if !users.contains(where: { $0.phone == user.userPhone }) {
                if let image = ProfileImageEnum(rawValue: user.userImage) {
                    modelContext.insert(UserData(userId: user.userId, name: user.userName, phone: user.userPhone, image: image, imageUrl: nil))
                } else {
                    modelContext.insert(UserData(userId: user.userId, name: user.userName, phone: user.userPhone, image: .owl, imageUrl: user.userImage))
                }
                saveModelContext()
            }
        }
    }
    
    func getCurrentUser () -> UserData? {
        if let users = getAllUsers(),
           let currentUser = UserDefaultsService.shared.getCurrentUser(),
           let user = users.first(where: { $0.phone == currentUser.userPhone }) {
            return user
        } else { return nil }
    }
    
    func getUserByUserId (_ id: String) -> UserData? {
        if let users = getAllUsers() {
            return users.first(where: { $0.userId == id })
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
    
    func addContact (name: String, phone: String) {
        if let users = getAllUsers(excludeLoggedUser: true) {
            if !users.contains(where: { $0.phone == phone }) {
                modelContext.insert(UserData(name: name, phone: phone))
                saveModelContext()
            }
        }
    }
}
