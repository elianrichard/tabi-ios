//
//  CurrentUserDefaults.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

struct CurrentUserDefaults: Codable {
    let userName: String
    let userPhone: String
    let userImage: ProfileImageEnum.ID
    let userId: String

    var isGuest: Bool { userPhone == "Guest" }
}

extension UserDefaultsService {
    func saveCurrentUser (user: CurrentUserDefaults) {
        setValue(user, forKey: .currentUserDetails)
    }
    
    func getCurrentUser () -> CurrentUserDefaults? {
        return getValue(forKey: .currentUserDetails, ofType: CurrentUserDefaults.self)
    }
    
    func deleteCurrentUser () {
        deleteKeyValue(forKey: .currentUserDetails)
    }
}
