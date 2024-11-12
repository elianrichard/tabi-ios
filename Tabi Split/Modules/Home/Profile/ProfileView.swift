//
//  ProfileView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 29/10/24.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    var body: some View {
        VStack{
            TopNavigation(title: "Profile")
            VStack(spacing: .spacingLarge){
                HStack{
                    HStack(alignment: .center, spacing: .spacingTight){
                        UserAvatar(userData: profileViewModel.user)
                        VStack(alignment: .leading){
                            Text(profileViewModel.user.name)
                                .font(.tabiSubtitle)
                            Text(profileViewModel.user.phone)
                                .font(.tabiBody)
                        }
                        Spacer()
                        Button{
                            routes.navigate(to: .EditProfile)
                        }label: {
                            Image(systemName: "pencil")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16)
                        }
                        .accentColor(.textBlack)
                    }
                }
                
                VStack(spacing: .spacingTight){
                    HStack(spacing: .spacingTight){
                        Icon(.creditCard, size: 20)
                        Text("Payment methods")
                            .font(.tabiHeadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .frame(width: 24, height: 24)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        routes.navigate(to: .PaymentMethods)
                    }
                    Divider()
                    Button {
                        Task {
                            let isSuccess = await profileViewModel.logout()
                            
                            if isSuccess {
                                routes.navigate(to: .LoginView)
                            }
                        }
                    } label: {
                        HStack(spacing: .spacingTight){
                            Icon(.logout, size: 20)
                            Text("Log Out")
                                .font(.tabiHeadline)
                                .foregroundStyle(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.black)
                        }
                    }
                    Divider()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.spacingMedium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ProfileView()
        .environment(Routes())
        .environment(ProfileViewModel())
}
