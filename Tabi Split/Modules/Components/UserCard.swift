//
//  UserCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/11/24.
//

import SwiftUI

struct UserCard : View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    var user: UserData
    var isShowYouText: Bool = true
    var isShowGuestPhoneText: Bool = false
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            UserAvatar(userData: user)
            VStack(alignment: .leading, spacing: .spacingXSmall) {
                Text("\(user.name)\((isShowYouText && profileViewModel.isCurrentUser(user)) ? " (You)" : "")")
                    .font(.tabiHeadline)
                    .foregroundStyle(.textBlack)
                if user.phone != "" {
                    Text((isShowGuestPhoneText && profileViewModel.isGuest) ? "You entered as a Guest" : user.phone)
                        .font(.tabiBody)
                        .foregroundColor(.textGrey)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    UserCard(user: UserData(name: "Testing", phone: "628123456789"))
}
