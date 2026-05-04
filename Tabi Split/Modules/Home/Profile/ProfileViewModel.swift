//
//  ProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 30/10/24.
//

import SwiftUI

@Observable
final class ProfileViewModel{
    var user: UserData = UserData(name: "unknown", phone: "unknown")
    var userPaymentMethods: [PaymentMethod] = []

    var isApiCallLoading: Bool = false
    var error: AppError?
    
    var isGuest: Bool {
        return UserDefaultsService.shared.getCurrentUser()?.isGuest ?? true
    }
    
    @MainActor
    func logout() async -> Bool {
        do {
            if !isGuest {
                isApiCallLoading = true
                try await AuthenticationService.shared.logout()
            }
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            user = UserData(name: "unknown", phone: "unknown")
        } catch {
            self.error = .from(error)
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
            let updatedUser = CurrentUserDefaults(userName: editProfileViewModel.nameText, userPhone: editProfileViewModel.phoneText, userImage: chosenImage.rawValue, userId: "userId")
            if !isGuest {
                let _ = try await ProfileService.shared.editProfile(user: updatedUser)
            }
            UserDefaultsService.shared.saveCurrentUser(user: updatedUser)
            user.name = editProfileViewModel.nameText
            user.phone = editProfileViewModel.phoneText
            if let image = editProfileViewModel.chosenImage {
                user.image = image.id
            }
            SwiftDataService.shared.saveModelContext()
        } catch {
            self.error = .from(error)
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
        if isGuest { return }
        Task {
            do {
                isApiCallLoading = true
                let freshUser = try await ProfileService.shared.getCurrentProfile()
                user.update(fromUserBase: freshUser)
            } catch {
                self.error = .from(error)
            }
            isApiCallLoading = false
        }
    }
    
    @MainActor
    func deleteUser () async -> Bool {
        do {
            if !isGuest {
                isApiCallLoading = true
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
        
        isApiCallLoading = false
        return true
    }
    
    func isCurrentUser (_ userData: UserData) -> Bool {
        return userData == user || userData.phone == user.phone
    }
}
