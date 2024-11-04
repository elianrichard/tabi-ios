//
//  UserAvatar.swift
//  Tabi Split
//
//  Created by Elian Richard on 03/11/24.
//

import SwiftUI

struct UserAvatar : View {
    var userData: UserData
    var isShowName: Bool = false
    
    var images: [ImageResource] = [.samplePersonProfile1, .samplePersonProfile2, .samplePersonProfile3]
    
    var body: some View {
        VStack (spacing: .spacingSmall) {
            Image(images.randomElement() ?? images[0])
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            if isShowName {
                Text(userData.name.getFirstName())
                    .font(.tabiBody)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .frame(maxWidth: 40, maxHeight: 20)
            }
        }
    }
}

#Preview {
    UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), isShowName: false)
    UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), isShowName: true)
    HStack (alignment: .top) {
        UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), isShowName: true)
        UserAvatar(userData: UserData(name: "Vincensia", phone: "Phone"), isShowName: true)
        UserAvatar(userData: UserData(name: "SuperLognName Richard", phone: "Phone"), isShowName: true)
        UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), isShowName: true)
    }
}
