//
//  GuestLoginViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 18/11/24.
//


import Foundation

@Observable
class GuestLoginViewModel {
    var name: String = ""
    var nameError: String?
    
    @MainActor
    func login() -> Bool {
        guard validateInput() else {
            print("Cannot login: form is invalid")
            return false
        }
        let user = CurrentUserDefaults(userName: name, userPhone: "Guest", userImage: "owl", userId: "")
        UserDefaultsService.shared.saveCurrentUser(user: user)
        SwiftDataService.shared.saveCurrentUser(user: user)
        return true
    }
    
    func validateInput () -> Bool {
        var isValid = true
        nameError = nil
        
        if name == "" {
            nameError = "Please input your name"
            isValid = false
        }
        
        return isValid
    }
}
