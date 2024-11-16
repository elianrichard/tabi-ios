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
    @State var editProfileViewModel = EditProfileViewModel()
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack{
            TopNavigation(title: "Edit Profile")
            
            VStack(spacing: .spacingTight){
                Image(uiImage: editProfileViewModel.profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
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
                        editProfileViewModel.toggleProfileImagePick = true
                    }
                
                VStack(spacing: .spacingRegular){
                    InputWithLabel(label: "Full Name", placeholder: "Full Name", text: $editProfileViewModel.nameText, focusedField: $focusedField, focusCase: .field1)
//                    TEMPORARILY DISABLED: PHONE NUMBER EDIT
                    InputWithLabel(label: "Phone Number", placeholder: "Phone Number", text: $editProfileViewModel.phoneText, isDisabled: true, focusedField: $focusedField, focusCase: .field2)
                }
            }
            
            Spacer()
            CustomButton(text: "Save") {
                profileViewModel.updateProfile(editProfileViewModel: editProfileViewModel)
                routes.navigateBack()
            }
        }
        .onAppear{
            editProfileViewModel.populateData(profileViewModel: profileViewModel)
        }
        .sheet(isPresented: Bindable(editProfileViewModel).toggleProfileImagePick){
            ProfileImageSheet(editProfileViewModel: $editProfileViewModel)
                .presentationDetents([.height(editProfileViewModel.contentHeight)])
                .presentationDragIndicator(.visible)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
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
