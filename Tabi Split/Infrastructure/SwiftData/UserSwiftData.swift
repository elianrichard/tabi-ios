//
//  UserSwiftData.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

import Foundation
import SwiftData
import Contacts
import OSLog

private let userLogger = Logger(subsystem: "com.tabi.split", category: "SwiftData.User")

extension SwiftDataService {
    @MainActor
    func getAllUsers(excludeLoggedUser: Bool = false, isUnique: Bool = false) -> [UserData]? {
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
            if let currentUser = UserDefaultsService.shared.getCurrentUser(), excludeLoggedUser {
                return users.filter { $0.phone != currentUser.userPhone }
            }
            return users
        } catch {
            userLogger.error("getAllUsers failed: \(error.localizedDescription)")
            return nil
        }
    }

    @MainActor
    func deleteUsersWithNoId() {
        guard let users = getAllUsers() else { return }
        for user in users where user.userId == "" {
            modelContext.delete(user)
        }
    }

    @MainActor
    func saveCurrentUser(user: CurrentUserDefaults) {
        guard let users = getAllUsers() else { return }
        guard !users.contains(where: { $0.phone == user.userPhone }) else { return }
        if let image = ProfileImageEnum(rawValue: user.userImage) {
            modelContext.insert(UserData(userId: user.userId, name: user.userName, phone: user.userPhone, image: image, imageUrl: nil))
        } else {
            modelContext.insert(UserData(userId: user.userId, name: user.userName, phone: user.userPhone, image: .owl, imageUrl: user.userImage))
        }
        saveModelContext()
    }

    @MainActor
    func getCurrentUser() -> UserData? {
        guard let users = getAllUsers(),
              let currentUser = UserDefaultsService.shared.getCurrentUser() else { return nil }
        return users.first(where: { $0.phone == currentUser.userPhone })
    }

    @MainActor
    func getUserByUserId(_ id: String) -> UserData? {
        return getAllUsers()?.first(where: { $0.userId == id })
    }

    @MainActor
    func editCurrentUser(name: String, phone: String, image: ProfileImageEnum.ID? = nil, imageUrl: String? = nil) {
        guard let user = getCurrentUser() else { return }
        user.name = name
        user.phone = phone
        if let image { user.image = image }
        if let imageUrl { user.imageUrl = imageUrl }
        saveModelContext()
    }

    @MainActor
    func deleteAllUser() {
        deleteModelContext(type: UserData.self)
    }

    @MainActor
    func addContact(name: String, phone: String) {
        if let users = getAllUsers(excludeLoggedUser: true),
           !users.contains(where: { $0.phone == phone }) {
            modelContext.insert(UserData(name: name, phone: phone))
            saveModelContext()
        }
    }
}
