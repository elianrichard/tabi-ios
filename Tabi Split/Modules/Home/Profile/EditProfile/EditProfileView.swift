//
//  EditProfile.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 29/10/24.
//

import Foundation
import SwiftUI

struct EditProfileView: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) private var profileViewModel
    @State var viewModel = EditProfileViewModel()
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack{
            TopNavigation(title: "Edit Profile")
            
            VStack(spacing: .spacingTight){
                UserAvatar(userData: profileViewModel.user, size: 90)
                    .overlay {
                        VStack {
                            Circle()
                                .stroke(.bgWhite, lineWidth: 4)
                                .fill(.buttonBlue)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Icon(systemName: "pencil", color: .bgWhite, size: 14)
                                }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .onTapGesture {
                        profileViewModel.toggleProfileImagePick = true
                    }
                
                VStack(spacing: .spacingRegular){
                    InputWithLabel(label: "Full Name", placeholder: "Full Name", text: $viewModel.user.name, focusedField: $focusedField, focusCase: .field1)
//                    TEMPORARILY DISABLED: PHONE NUMBER EDIT
                    InputWithLabel(label: "Phone Number", placeholder: "Phone Number", text: $viewModel.user.phone, isDisabled: true, focusedField: $focusedField, focusCase: .field2)
                }
            }
            
            Spacer()
            CustomButton(text: "Save") {
                // Handle user data saving in cloud
                profileViewModel.user.name = viewModel.user.name
                profileViewModel.user.phone = viewModel.user.phone
                profileViewModel.profileImage = viewModel.profileImage
                profileViewModel.savedIndex = viewModel.savedIndex
                routes.navigateBack()
            }
        }
        .onAppear{
            viewModel.user = profileViewModel.user
            viewModel.profileImage = profileViewModel.profileImage
            viewModel.savedIndex = profileViewModel.savedIndex
        }
        .sheet(isPresented: Bindable(profileViewModel).toggleProfileImagePick){
            ProfileImageSheet(editProfileViewModel: $viewModel)
                .presentationDetents([.height(profileViewModel.contentHeight)])
        }
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacingMedium)
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
    }
}

#Preview {
    EditProfileView()
        .environment(Routes())
        .environment(ProfileViewModel())
}
