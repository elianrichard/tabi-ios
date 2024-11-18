//
//  ProfileImagePickViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 01/11/24.
//

import Foundation
import SwiftUI

@Observable
final class ProfileImagePickViewModel {
    var chosenImage: ProfileImageEnum?
    var uploadedImage: UIImage?
    var isSelectUpload: Bool = false {
        didSet {
            if isSelectUpload {
                chosenImage = nil
            }
        }
    }
    
    func populateData (editProfileViewModel: EditProfileViewModel) {
        if let image = editProfileViewModel.chosenImage {
            chosenImage = image
        }
        if let upload = editProfileViewModel.uploadedImage {
            uploadedImage = upload
            isSelectUpload = true
        }
    }
}
