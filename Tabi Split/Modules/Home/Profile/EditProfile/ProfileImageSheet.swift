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
    @State var viewModel = ProfileImagePickViewModel()
    
    var body: some View {
        VStack(){
            SheetXButton(toggle: Bindable(profileViewModel).toggleProfileImagePick)
            VStack(spacing: .spacingMedium){
                Text("Select Image")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: .spacingMedium){
                    ForEach(1...profileViewModel.images.count+1, id: \.self) { index in
                        if index == 1 {
                            Circle()
                                .overlay{
                                    if viewModel.chosenIndex == 1 {
                                        if let image = viewModel.chosenImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())
                                        }else{
                                            Image(uiImage: profileViewModel.profileImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())
                                        }
                                    }else{
                                        Image(systemName: "photo")
                                            .resizable()
                                            .foregroundColor(.textGrey)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 25, height: 25)
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .background{
                                    Circle()
                                        .frame(width: 66, height: 66)
                                        .foregroundColor(.buttonGreen)
                                        .opacity(viewModel.chosenIndex == index ? 1 : 0)
                                }
                                .foregroundColor(.uiGray)
                                .onTapGesture {
                                    profileViewModel.toggleProfileImageUpload.toggle()
                                }
                                .onChange(of: viewModel.chosenImage) {
                                    if viewModel.chosenIndex != 1 {
                                        viewModel.chosenIndex = 1
                                    }
                                }
                        }
                        else{
                            Circle()
                                .foregroundColor(.uiGray)
                                .overlay(content: {
                                    Image(uiImage: profileViewModel.images[index-2])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                })
                                .frame(width: 60, height: 60)
                                .background{
                                    Circle()
                                        .frame(width: 66, height: 66)
                                        .foregroundColor(.buttonGreen)
                                        .opacity(viewModel.chosenIndex == index ? 1 : 0)
                                }
                                .onTapGesture {
                                    if viewModel.chosenIndex != index {
                                        viewModel.chosenIndex = index
                                    }
                                }
                        }
                    }
                }
                CustomButton(text: "Done") {
                    editProfileViewModel.savedIndex = viewModel.chosenIndex
                    if viewModel.chosenIndex == 1 {
                        if let image = viewModel.chosenImage {
                            editProfileViewModel.profileImage = image
                        }
                    }else{
                        editProfileViewModel.profileImage = profileViewModel.images[viewModel.chosenIndex-2]
                    }
                    profileViewModel.toggleProfileImagePick.toggle()
                }
            }
        }
        .onAppear{
            viewModel.chosenIndex = editProfileViewModel.savedIndex
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        profileViewModel.contentHeight = geometry.size.height
                    }
            }
        )
        .sheet(isPresented: Bindable(profileViewModel).toggleProfileImageUpload){
            ImagePicker(selectedImage: $viewModel.chosenImage)
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        .padding([.top], 10)
    }
}

#Preview {
    ProfileImageSheet(editProfileViewModel: .constant(EditProfileViewModel()))
        .environment(ProfileViewModel())
}
