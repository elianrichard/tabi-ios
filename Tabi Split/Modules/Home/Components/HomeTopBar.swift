//
//  HomeTopBar.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct HomeTopBar: View {
    var body: some View {
        HStack (spacing: 10){
            HStack (spacing: 10){
                Image(.sampleUserProfile1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2),radius: 4, y: 3)
                Text("Hi, User!")
                    .font(.tabiHeadline)
            }
            Spacer()
            Button {
                print("Notifications")
            } label: {
                Icon(systemName: "bell", size: 20)
            }
        }
    }
}
