//
//  ProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 30/10/24.
//

import SwiftUI

@Observable
final class ProfileViewModel{
    var user: UserData = UserData(name: "unknown", email: "unknown")
    var userPaymentMethods: [PaymentMethod] = []

    var isApiCallLoading: Bool = false
    
    // A guest is a server-backed credential-less account (kind == "guest" from the
    // backend, carried on the stored current user). It runs every authed endpoint
    // like a real account; the only differences are UI affordances, so most call
    // sites no longer branch on this.
    var isGuest: Bool {
        return UserDefaultsService.shared.getCurrentUser()?.kind == "guest"
    }

    @MainActor
    func logout() async -> Bool {
        do {
            isApiCallLoading = true
            try await AuthenticationService.shared.logout()
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            try? KeychainService.shared.clearTokens()
            SessionState.shared.sessionExpiredBanner = false
            user = UserData(name: "unknown", email: "unknown")
        } catch {
            print("Logout failed: \(error)")
            isApiCallLoading = false
            return false
        }

        isApiCallLoading = false
        return true
    }
    
    @MainActor
    func updateProfile (editProfileViewModel: EditProfileViewModel) async -> Bool {
        guard let chosenImage = editProfileViewModel.chosenImage else {
            isApiCallLoading = false
            return false
        }
        do {
            isApiCallLoading = true
            // Email is provider-owned and not editable; preserve the existing value.
            // Preserve the real userId (JWT subject) — it identifies the account and
            // gates event-edit ownership; a placeholder here would break isUserCreator.
            let existingUserId = UserDefaultsService.shared.getCurrentUser()?.userId ?? user.userId
            // Preserve the account kind (real/guest) so the stored current user
            // keeps its guest marker across a profile edit.
            let existingKind = UserDefaultsService.shared.getCurrentUser()?.kind ?? "real"
            let updatedUser = CurrentUserDefaults(userName: editProfileViewModel.nameText, userEmail: user.email, userImage: chosenImage.rawValue, userId: existingUserId, kind: existingKind)
            let _ = try await ProfileService.shared.editProfile(user: updatedUser)
            UserDefaultsService.shared.saveCurrentUser(user: updatedUser)
            user.name = editProfileViewModel.nameText
            if let image = editProfileViewModel.chosenImage {
                user.image = image.id
            }
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Update profile failed: \(error)")
            isApiCallLoading = false
            return false
        }
        isApiCallLoading = false
        return true
    }
    
    @MainActor
    func refreshUserData () {
        if let currentUser = SwiftDataService.shared.getCurrentUser() {
            user = currentUser
        }
        Task {
            do {
                isApiCallLoading = true
                let freshUser = try await ProfileService.shared.getCurrentProfile()
                user.update(fromUserBase: freshUser)
            } catch {
                print("Refresh profile failed: \(error)")
            }
            isApiCallLoading = false
        }
    }
    
    @MainActor
    func deleteUser () async -> Bool {
        do {
            isApiCallLoading = true
            try await ProfileService.shared.deleteUser()
            try await AuthenticationService.shared.logout()
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            try? KeychainService.shared.clearTokens()
            SessionState.shared.sessionExpiredBanner = false
            user = UserData(name: "unknown", email: "unknown")
        } catch {
            print("User delete failed: \(error)")
            return false
        }

        isApiCallLoading = false
        return true
    }
    
    func isCurrentUser (_ userData: UserData) -> Bool {
        if userData == user { return true }
        // Match on userId first (authoritative); fall back to email. Empty values
        // never match, so an unresolved/placeholder current user ("unknown") or a
        // guest (real userId, no email) does not mis-identify empty-identity rows
        // as "you".
        if !userData.userId.isEmpty && !user.userId.isEmpty {
            return userData.userId == user.userId
        }
        if !userData.email.isEmpty && !user.email.isEmpty && user.email != "unknown" {
            return userData.email == user.email
        }
        return false
    }
}
