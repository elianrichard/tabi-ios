//
//  UserAvatar.swift
//  Tabi Split
//
//  Created by Elian Richard on 03/11/24.
//

import SwiftUI

enum AvatarTextPositionEnum {
    case bottom, right
}

struct UserAvatar : View {
    var userData: UserData
    var namePosition: AvatarTextPositionEnum?
    
    var images: [ImageResource] = [.samplePersonProfile1, .samplePersonProfile2, .samplePersonProfile3]
    
    var body: some View {
        VStack (spacing: .spacingSmall) {
            HStack (spacing: .spacingTight) {
                Image(images.randomElement() ?? images[0])
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                if namePosition == .right {
                    Text(userData.name.getFirstName())
                        .font(.tabiHeadline)
                        .lineLimit(1)
                }
            }
            if namePosition == .bottom {
                Text(userData.name.getFirstName())
                    .font(.tabiBody)
                    .lineLimit(1)
                    .frame(maxWidth: 40, maxHeight: 20)
            }
        }
    }
}

#Preview {
    UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"))
    UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), namePosition: .right)
    UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), namePosition: .bottom)
    HStack (alignment: .top) {
        UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), namePosition: .bottom)
        UserAvatar(userData: UserData(name: "Vincensia", phone: "Phone"), namePosition: .bottom)
        UserAvatar(userData: UserData(name: "SuperLognName Richard", phone: "Phone"), namePosition: .bottom)
        UserAvatar(userData: UserData(name: "Elian Richard", phone: "Phone"), namePosition: .bottom)
    }
}
