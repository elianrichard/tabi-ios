//
//  HomeTopBar.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct HomeTopBar: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    var body: some View {
        HStack (spacing: 10){
            HStack (spacing: 10){
                Circle()
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(uiImage: profileViewModel.profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                    .foregroundColor(.uiGray)
                    .onTapGesture {
                        routes.navigate(to: .Profile)
                    }
                Text("Hi, " + profileViewModel.user.name + "!")
                    .font(.tabiHeadline)
            }
            Spacer()
            Button {
                print("Notifications")
            } label: {
                Icon(.notification)
            }
        }
    }
}
