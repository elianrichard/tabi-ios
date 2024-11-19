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
                    HStack(alignment: .center, spacing: .spacingTight) {
                        UserCard(user: profileViewModel.user, isShowGuestPhoneText: true)
                        Spacer()
                        if !profileViewModel.isGuest {
                            Icon(systemName: "pencil", color: .textBlack, size: 16) {
                                routes.navigate(to: .EditProfile)
                            }
                        }
                    }
                }
                
                if profileViewModel.isGuest {
                    VStack (spacing: .spacingLarge) {
                        Image(.initialOnboarding)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                        Text("Let’s register to keep all your events and expenses saved!")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        CustomButton(text: "Sign In", type: .tertiary, iconResource: .logout) {
                            routes.navigate(to: .LoginView)
                        }
                    }
                }
                
                if !profileViewModel.isGuest {
                    VStack(alignment: .leading, spacing: .spacingTight) {
                        //                    TEMPORARILY DISABLED: PAYMENT METHOD
                        if (false) {
                            Text("Settings")
                                .font(.tabiBody)
                            Button {
                                routes.navigate(to: .PaymentMethods)
                            } label: {
                                HStack(spacing: .spacingTight){
                                    Icon(systemName: "wallet.bifold")
                                    Text("Payment methods")
                                        .font(.tabiHeadline)
                                        .foregroundStyle(.textBlack)
                                    Spacer()
                                    Icon(systemName: "chevron.right", size: 16)
                                }
                                .padding(.vertical, .spacingSmall)
                                .contentShape(Rectangle())
                            }
                            Divider()
                        }
                        Button {
                            Task {
                                let isSuccess = await profileViewModel.logout()
                                
                                if isSuccess {
                                    routes.navigate(to: .LoginView)
                                }
                            }
                        } label: {
                            HStack(spacing: .spacingTight){
                                Icon(.logout, color: .buttonRed, size: 20)
                                Text("Log Out")
                                    .font(.tabiHeadline)
                                    .foregroundStyle(.buttonRed)
                                Spacer()
                            }
                            .padding(.vertical, .spacingSmall)
                            .contentShape(Rectangle())
                        }
                    }
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
