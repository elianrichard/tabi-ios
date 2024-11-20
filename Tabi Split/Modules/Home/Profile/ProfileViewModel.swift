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

    var isLogoutLoading: Bool = false
    var isDeleteLoading: Bool = false
    var isUpdateProfileLoading: Bool = false
    var isRefreshProfileLoading: Bool = false
    
    var isGuest: Bool {
        return user.phone == "Guest"
    }
    
    @MainActor
    func logout() async -> Bool {
        isLogoutLoading = true
        var isSuccess = false
        do {
            try await AuthenticationService.shared.logout()
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            user = UserData(name: "unknown", phone: "unknown")
            isSuccess = true
        } catch {
            print("Logout failed: \(error)")
            isSuccess = false
        }
        
        isLogoutLoading = false
        return isSuccess
    }
    
    @MainActor
    func updateProfile (editProfileViewModel: EditProfileViewModel) async -> Bool {
        var isSuccess = false
        isUpdateProfileLoading = true
        guard let chosenImage = editProfileViewModel.chosenImage else { return isSuccess }
        do {
            let updatedUser = CurrentUserDefaults(userName: editProfileViewModel.nameText, userPhone: editProfileViewModel.phoneText, userImage: chosenImage.rawValue, userId: "userId")
            let _ = try await ProfileService.shared.editProfile(user: updatedUser)
            UserDefaultsService.shared.saveCurrentUser(user: updatedUser)
            user.name = editProfileViewModel.nameText
            user.phone = editProfileViewModel.phoneText
            if let image = editProfileViewModel.chosenImage {
                user.image = image.id
            }
            SwiftDataService.shared.saveModelContext()
            isSuccess = true
        } catch {
            print("Update profile failed: \(error)")
            isSuccess = false
        }
        isUpdateProfileLoading = false
        return isSuccess
    }
    
    @MainActor
    func refreshUserData () {
        if let currentUser = SwiftDataService.shared.getCurrentUser() {
            user = currentUser
        }
        if isGuest { return }
        Task {
            isRefreshProfileLoading = true
            do {
                let freshUser = try await ProfileService.shared.getCurrentProfile()
                user.name = freshUser.userName
                user.phone = freshUser.userPhone
                user.image = freshUser.userImage
            } catch {
                print("Refresh profile failed: \(error)")
            }
            isRefreshProfileLoading = false
        }
    }
    
    @MainActor
    func deleteUser () async -> Bool {
        isDeleteLoading = true
        var isSuccess = false
        do {
            try await ProfileService.shared.deleteUser()
            try await AuthenticationService.shared.logout()
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
            user = UserData(name: "unknown", phone: "unknown")
            isSuccess = true
        } catch {
            print("User delete failed: \(error)")
            isSuccess = false
        }
        
        isDeleteLoading = false
        return isSuccess
    }
    
    func isCurrentUser (_ userData: UserData) -> Bool {
        return userData == user || userData.phone == user.phone
    }
}
