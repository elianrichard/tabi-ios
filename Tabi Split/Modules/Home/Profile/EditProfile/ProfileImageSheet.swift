//
//  ProfileImageSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 29/10/24.
//

import Foundation
import SwiftUI

struct ProfileImageSheet: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Binding var editProfileViewModel: EditProfileViewModel
    @State var profileImagePickViewModel = ProfileImagePickViewModel()
    
    var body: some View {
        CustomSheet (xToggleBinding: Bindable(editProfileViewModel).toggleProfileImagePick) {
            VStack(alignment: .leading, spacing: .spacingMedium) {
                Text("Select Image")
                    .font(.tabiTitle)
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: .spacingTight) {
//                    TEMPORARILY DISABLED: UPLOAD USER DISPLAY PICTURE
                    if (false) {
                        Button {
                            if profileImagePickViewModel.uploadedImage == nil {
                                editProfileViewModel.toggleProfileImageUpload = true
                            } else {
                                profileImagePickViewModel.isSelectUpload = true
                            }
                        } label: {
                            Circle()
                                .fill(.uiGray)
                                .overlay {
                                    if let uploaded = profileImagePickViewModel.uploadedImage {
                                        Image(uiImage: uploaded)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .clipShape(Circle())
                                    } else {
                                        Icon(systemName: "photo", color: .textGrey)
                                    }
                                }
                                .padding(6)
                                .frame(width: 84, height: 84)
                                .background {
                                    if profileImagePickViewModel.isSelectUpload {
                                        Circle()
                                            .stroke(.buttonBlue, lineWidth: 4)
                                    }
                                }
                        }
                    }
                    ForEach(ProfileImageEnum.allCases) { image in
                        Button {
                            profileImagePickViewModel.chosenImage = image
                            profileImagePickViewModel.isSelectUpload = false
                        } label: {
                            Circle()
                                .fill(.uiGray)
                                .overlay {
                                    Image(image.resource)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                }
                                .padding(6)
                                .frame(width: 84, height: 84)
                                .background {
                                    if profileImagePickViewModel.chosenImage == image {
                                        Circle()
                                            .stroke(.buttonBlue, lineWidth: 4)
                                    }
                                }
                        }
                    }
                }
                CustomButton(text: "Done") {
                    if let chosen = profileImagePickViewModel.chosenImage {
                        editProfileViewModel.chosenImage = chosen
                    } else if profileImagePickViewModel.isSelectUpload, let upload = profileImagePickViewModel.uploadedImage {
                        editProfileViewModel.uploadedImage = upload
                    }
                    editProfileViewModel.toggleProfileImagePick = false
                }
            }
        }
        .onAppear {
            profileImagePickViewModel.populateData(editProfileViewModel: editProfileViewModel)
        }
        .sheet(isPresented: Bindable(editProfileViewModel).toggleProfileImageUpload) {
            ImagePicker(selectedImage: $profileImagePickViewModel.uploadedImage) { _ in
                profileImagePickViewModel.isSelectUpload = true
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        editProfileViewModel.contentHeight = geometry.size.height
                    }
            }
        )
    }
}

#Preview {
    ProfileImageSheet(editProfileViewModel: .constant(EditProfileViewModel()))
        .environment(ProfileViewModel())
}
