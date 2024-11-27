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
    @State private var isShowDeleteSheet = false
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack{
            TopNavigation(title: "Edit Profile")
            
            VStack (spacing: .spacingLarge) {
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
                        InputWithLabel(label: "Phone Number", placeholder: "Phone Number", text: $editProfileViewModel.phoneText, focusedField: $focusedField, focusCase: .field2)
                    }
                }
                CustomButton(text: "Delete Account", type: .tertiary, customTextColor: .buttonRed) {
                    isShowDeleteSheet = true
                }
            }
            
            Spacer()
            CustomButton(text: profileViewModel.isApiCallLoading ? "Loading..." : "Save") {
                Task {
                    if await profileViewModel.updateProfile(editProfileViewModel: editProfileViewModel) {
                        routes.navigateBack()
                    }
                }
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
        .sheet(isPresented: $isShowDeleteSheet) {
            CustomSheet(xToggleBinding: $isShowDeleteSheet) {
                VStack (spacing: .spacingRegular) {
                    Image(.eventDelete)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    VStack (spacing: .spacingSmall) {
                        Text("Delete this account?")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text("All your events and expenses will be permanently deleted and cannot be recovered.")
                            .font(.tabiBody)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
                HStack {
                    CustomButton(text: "Cancel", type: .secondary) {
                        isShowDeleteSheet = false
                    }
                    CustomButton(text: profileViewModel.isApiCallLoading ? "Loading..." : "Delete", customBackgroundColor: .buttonRed) {
                        Task {
                            if await profileViewModel.deleteUser() {
                                isShowDeleteSheet = false
                                routes.navigate(to: .LoginView)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .presentationDetents([.medium])
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
