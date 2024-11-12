//
//  ProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 30/10/24.
//

import SwiftUI

@Observable
final class ProfileViewModel{
    var profileImage: UIImage = UIImage(imageLiteralResourceName: "Octopus")
    var toggleProfileImagePick: Bool = false
    var profileImageSettingsDetent = PresentationDetent.medium
    var savedIndex: Int = 5
    var images: [UIImage] = [UIImage(imageLiteralResourceName: "Wallet"), UIImage(imageLiteralResourceName: "Dragon"), UIImage(imageLiteralResourceName: "Owl"), UIImage(imageLiteralResourceName: "Octopus")]
    var contentHeight : CGFloat = 0
    var toggleProfileImageUpload: Bool = false
    var user: UserData = UserData(name: "You", phone: "628123456789", image: .owl)

    var isLoading: Bool = false
    let authService = AuthenticationService()
    
    func logout() async -> Bool {
        isLoading = true
        var isSuccess = false
        do {
            try await authService.logout()
            print("Logout successful!")
            isSuccess = true
        } catch {
            print("Logout failed: \(error)")
            isSuccess = false
        }
        
        isLoading = false
        return isSuccess
    }
  
    var userPaymentMethods: [PaymentMethod] = []
}
