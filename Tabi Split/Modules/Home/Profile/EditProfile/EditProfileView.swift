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
    
    var body: some View {
        VStack{
            TopNavigation(title: "Edit Profile")
            
            VStack(spacing: .spacingTight){
                ZStack{
                    Circle()
                        .frame(width: 90, height: 90)
                        .overlay {
                            Image(uiImage: viewModel.profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        }
                        .foregroundColor(.uiGray)
                    Circle()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.buttonDarkBlue)
                        .background(
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.bgWhite)
                        )
                        .overlay {
                            Image(systemName: "pencil")
                                .foregroundColor(.bgWhite)
                        }
                        .offset(CGSize(width: 30, height: 30))
                }
                .onTapGesture {
                    profileViewModel.toggleProfileImagePick.toggle()
                }
                
                VStack(spacing: .spacingRegular){                
                    InputWithLabel(label: "Fullname", placeholder: "Fullname", text: $viewModel.user.name, inputBackgroundColor: .bgWhite, inputCornerRadius: 16)
                    InputWithLabel(label: "Phone Number", placeholder: "Phone Number", text: $viewModel.user.phone, inputBackgroundColor: .bgWhite, inputCornerRadius: 16)
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
        .background(.bgWhite)
    }
}

#Preview {
    EditProfileView()
        .environment(Routes())
        .environment(ProfileViewModel())
}
