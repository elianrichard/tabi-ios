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
    var nameText: String = ""
    var phoneText: String = ""
    
    var profileImage: UIImage = UIImage(resource: .owl)
    var uploadedImage: UIImage? = nil {
        didSet {
            if let image = uploadedImage {
                profileImage = image
            }
        }
    }
    var chosenImage: ProfileImageEnum? = nil {
        didSet {
            if let image = chosenImage {
                profileImage = UIImage(resource: image.resource)
            }
        }
    }
    
    var toggleProfileImagePick: Bool = false
    var toggleProfileImageUpload: Bool = false
    var contentHeight : CGFloat = 0
    
    func populateData(profileViewModel: ProfileViewModel) {
        nameText = profileViewModel.user.name
        phoneText = profileViewModel.user.phone
        
        if let chosenTemplateImage = ProfileImageEnum(rawValue: profileViewModel.user.image) {
            chosenImage = chosenTemplateImage
        }
    }
}
