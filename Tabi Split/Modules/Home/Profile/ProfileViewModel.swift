//
//  ProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 30/10/24.
//

import SwiftUI

@Observable
final class ProfileViewModel{
    var user: UserData = UserData(name: "test", phone: "test")
    var userPaymentMethods: [PaymentMethod] = []

    var isLogoutLoading: Bool = false
    
    func logout() async -> Bool {
        isLogoutLoading = true
        var isSuccess = false
        do {
            try await AuthenticationService().logout()
            print("Logout successful!")
            isSuccess = true
        } catch {
            print("Logout failed: \(error)")
            isSuccess = false
        }
        
        isLogoutLoading = false
        return isSuccess
    }
    
    @MainActor
    func updateProfile (editProfileViewModel: EditProfileViewModel) {
        user.name = editProfileViewModel.nameText
        //        TEMPORARILY DISABLED: UPDATE PHONE NUMBER
        //        user.phone = editProfileViewModel.user.phone
        if let image = editProfileViewModel.chosenImage {
            user.image = image.id
        }
        SwiftDataService.shared.editCurrentUser(name: editProfileViewModel.nameText, phone: editProfileViewModel.phoneText, image: editProfileViewModel.chosenImage?.id)
//        TO DO: UPDATE PROFILE TO BACKEND
    }
    
    func isCurrentUser (_ userData: UserData) -> Bool {
        return userData.phone == user.phone
    }
}
