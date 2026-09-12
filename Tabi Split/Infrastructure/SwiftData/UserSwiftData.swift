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
    func getAllUsers (excludeLoggedUser: Bool = false, isUnique: Bool = false) -> [UserData]? {
        let fetchDescriptor = FetchDescriptor<UserData>()
        do {
            var users = try modelContext.fetch(fetchDescriptor)
            if isUnique {
                users = users.reduce(into: [UserData]()) { result, user in
                    if !result.contains(where: { $0.userId == user.userId }) {
                        result.append(user)
                    }
                }
            }
            if let currentUser = UserDefaultsService.shared.getCurrentUser(),
               excludeLoggedUser {
                return users.filter{ $0.email != currentUser.userEmail }
            } else { return users }
        } catch {
            TabiSchema.log.error("fetch users failed: \(String(describing: error), privacy: .public)")
            return nil
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
            // Match the existing row by userId when present (authoritative — every
            // server-backed account, guests included, has a real userId), so a
            // guest with an empty email is not deduped against other empty-email
            // rows. Fall back to email only for legacy rows lacking a userId.
            let exists = users.contains(where: { isSameCurrentUser($0, user) })
            if !exists {
                if let image = ProfileImageEnum(rawValue: user.userImage) {
                    modelContext.insert(UserData(userId: user.userId, name: user.userName, email: user.userEmail, image: image, imageUrl: nil))
                } else {
                    modelContext.insert(UserData(userId: user.userId, name: user.userName, email: user.userEmail, image: .owl, imageUrl: user.userImage))
                }
                saveModelContext()
            }
        }
    }

    func getCurrentUser () -> UserData? {
        if let users = getAllUsers(),
           let currentUser = UserDefaultsService.shared.getCurrentUser(),
           let user = users.first(where: { isSameCurrentUser($0, currentUser) }) {
            return user
        } else { return nil }
    }

    /// Whether a stored UserData row is the current user: by userId when both are
    /// non-empty (authoritative), else by email. Prevents empty-email guest rows
    /// from colliding with other empty-email rows.
    private func isSameCurrentUser(_ row: UserData, _ current: CurrentUserDefaults) -> Bool {
        if !row.userId.isEmpty && !current.userId.isEmpty {
            return row.userId == current.userId
        }
        return !current.userEmail.isEmpty && row.email == current.userEmail
    }
    
    func getUserByUserId (_ id: String) -> UserData? {
        if let users = getAllUsers() {
            return users.first(where: { $0.userId == id })
        } else { return nil }
    }
    
    func editCurrentUser (name: String, email: String, image: ProfileImageEnum.ID? = nil, imageUrl: String? = nil) {
        if let user = getCurrentUser() {
            user.name = name
            user.email = email
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

    func addContact (name: String, email: String) {
        if let users = getAllUsers(excludeLoggedUser: true) {
            if !users.contains(where: { $0.email == email }) {
                modelContext.insert(UserData(name: name, email: email))
                saveModelContext()
            }
        }
    }
}
