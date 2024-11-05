//
//  EditProfileViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 01/11/24.
//

import Foundation
import SwiftUI

@Observable
class EditProfileViewModel{
    var user: UserData = UserData(name: "", phone: "")
    var profileImage: UIImage = UIImage()
    var savedIndex: Int = 5
}
