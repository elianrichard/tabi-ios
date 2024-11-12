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
    @Bindable var homeViewModel: HomeViewModel
    
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
                routes.navigate(to: .InboxView)
            } label: {
                Icon(.notification)
                    .overlay {
                        if (homeViewModel.notificationCount > 0) {
                            Text("\(homeViewModel.notificationCount)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(.textWhite)
                                .font(.tabiBody)
                                .padding(2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.buttonRed)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                        
                    }
                    .padding(.trailing, homeViewModel.notificationCount > 0 ? 10 : 0)
            }
        }
    }
}
