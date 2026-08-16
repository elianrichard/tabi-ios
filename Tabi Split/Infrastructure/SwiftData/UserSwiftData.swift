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

    /// Convert pre-login Guest rows (UserData phone == "Guest", events.creatorId == "") into the
    /// authed user. Called from LoginViewModel right after a successful login, before
    /// saveCurrentUser inserts a fresh row.
    func promoteGuestUserData(to user: CurrentUserDefaults) {
        guard let users = getAllUsers() else { return }

        // Promote the Guest UserData (if any) so subsequent saveCurrentUser is a no-op.
        if let guestUser = users.first(where: { $0.phone == "Guest" }) {
            guestUser.userId = user.userId
            guestUser.name = user.userName
            guestUser.phone = user.userPhone
            if let image = ProfileImageEnum(rawValue: user.userImage) {
                guestUser.image = image.id
                guestUser.imageUrl = nil
            } else {
                guestUser.image = ProfileImageEnum.owl.id
                guestUser.imageUrl = user.userImage
            }
        }

        // Patch creatorId on any Guest-era events (creatorId was "") so isUserCreator works.
        if let events = fetchAllEvents() {
            for event in events where event.creatorId.isEmpty {
                event.creatorId = user.userId
            }
        }

        saveModelContext()
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
