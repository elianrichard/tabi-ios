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
    @Environment(ProfileViewModel.self) private var profileViewModel
    var userData: UserData
    var namePosition: AvatarTextPositionEnum?
    var size: CGFloat = 40
    var customName: String?
    var isShowCurrentUserText: Bool = false
    var currentUserText: String = "You"
    
    var body: some View {
        VStack (spacing: .spacingSmall) {
            HStack (spacing: .spacingTight) {
                Image(ProfileImageEnum(rawValue: userData.image)?.resource ?? .owl)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                if namePosition == .right {
                    UserAvatarNameComponent(name: customName ?? userData.name.getFirstName(),
                                            isShowCurrentUserText: isShowCurrentUserText && profileViewModel.isCurrentUser(userData),
                                            currentUserText: currentUserText)
                }
            }
            if namePosition == .bottom {
                UserAvatarNameComponent(name: customName ?? userData.name.getFirstName(),
                                        isShowCurrentUserText: isShowCurrentUserText && profileViewModel.isCurrentUser(userData),
                                        currentUserText: currentUserText)
                    .frame(maxWidth: 40, maxHeight: 20)
            }
        }
    }
}

#Preview {
    UserAvatar(userData: UserData(name: "Elian Richard", email: "test@example.com"))
    UserAvatar(userData: UserData(name: "Elian Richard", email: "test@example.com"), namePosition: .right)
    UserAvatar(userData: UserData(name: "Elian Richard", email: "test@example.com"), namePosition: .bottom)
    HStack (alignment: .top) {
        UserAvatar(userData: UserData(name: "Elian Richard", email: "test@example.com"), namePosition: .bottom)
        UserAvatar(userData: UserData(name: "Vincensia", email: "test@example.com"), namePosition: .bottom)
        UserAvatar(userData: UserData(name: "SuperLognName Richard", email: "test@example.com"), namePosition: .bottom)
        UserAvatar(userData: UserData(name: "Elian Richard", email: "test@example.com"), namePosition: .bottom)
    }
}

struct UserAvatarNameComponent: View {
    var name: String
    var isShowCurrentUserText: Bool = false
    var currentUserText: String = "You"
    
    var body: some View {
        HStack {
            Text(name)
                .font(.tabiBody)
                .lineLimit(1)
            if isShowCurrentUserText {
                Text("(\(currentUserText))")
                    .font(.tabiHeadline)
                    .foregroundStyle(.textGrey)
            }
        }
    }
}
