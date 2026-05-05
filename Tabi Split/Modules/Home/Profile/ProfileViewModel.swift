//
//  ProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 30/10/24.
//

import SwiftUI

@Observable
final class ProfileViewModel {
    var user: UserData = UserData(name: "unknown", phone: "unknown")
    var userPaymentMethods: [PaymentMethod] = []

    var isApiCallLoading: Bool = false
    var error: AppError?

    var isGuest: Bool {
        UserDefaultsService.shared.getCurrentUser()?.isGuest ?? true
    }

    @MainActor
    func logout() async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        do {
            if !isGuest { try await AuthenticationService.shared.logout() }
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            user = UserData(name: "unknown", phone: "unknown")
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }

    @MainActor
    func updateProfile(editProfileViewModel: EditProfileViewModel) async -> Bool {
        guard let chosenImage = editProfileViewModel.chosenImage else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        do {
            let updatedUser = CurrentUserDefaults(
                userName: editProfileViewModel.nameText,
                userPhone: editProfileViewModel.phoneText,
                userImage: chosenImage.rawValue,
                userId: "userId"
            )
            if !isGuest { let _ = try await ProfileService.shared.editProfile(user: updatedUser) }
            UserDefaultsService.shared.saveCurrentUser(user: updatedUser)
            user.name = editProfileViewModel.nameText
            user.phone = editProfileViewModel.phoneText
            user.image = chosenImage.id
            SwiftDataService.shared.saveModelContext()
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }

    // Loads local data synchronously, then refreshes from the server in the background.
    @MainActor
    func refreshUserData() async {
        if let currentUser = SwiftDataService.shared.getCurrentUser() {
            user = currentUser
        }
        guard !isGuest else { return }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        do {
            let freshUser = try await ProfileService.shared.getCurrentProfile()
            user.update(fromUserBase: freshUser)
        } catch {
            self.error = .from(error)
        }
    }

    @MainActor
    func deleteUser() async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        do {
            if !isGuest {
                try await ProfileService.shared.deleteUser()
                try await AuthenticationService.shared.logout()
            }
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            user = UserData(name: "unknown", phone: "unknown")
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }

    func isCurrentUser(_ userData: UserData) -> Bool {
        userData == user || userData.phone == user.phone
    }
}
