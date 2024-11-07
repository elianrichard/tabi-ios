//
//  ProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 30/10/24.
//

import Foundation
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
    var user: UserData = UserData(name: "Dharma", phone: "082123733400")

    var isLoading: Bool = false
    var isLogoutSuccess: Bool = false
    let authService = AuthenticationService()
    
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
            isLogoutSuccess = true
            print("Logout successful!")
        } catch {
            print("Logout failed: \(error)")
            isLogoutSuccess = false
        }
        
        isLoading = false
    }
  
    var userPaymentMethods: [PaymentMethod] = []
}
