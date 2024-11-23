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
    var isShowYouText: Bool = false
    var isShowOwnerText: Bool = false
    var isShowPhoneText: Bool = true
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            UserAvatar(userData: user)
            VStack(alignment: .leading, spacing: .spacingXSmall) {
                HStack {
                    Text("\(user.name)")
                        .font(.tabiHeadline)
                        .foregroundStyle(.textBlack)
                    if isShowOwnerText {
                        Text("(Owner)")
                            .font(.tabiHeadline)
                            .foregroundStyle(.textGrey)
                    } else if isShowYouText && profileViewModel.isCurrentUser(user) {
                        Text("(You)")
                            .font(.tabiHeadline)
                            .foregroundStyle(.textGrey)
                    }
                }
                if (isShowPhoneText && user.phone != "") {
                    if !(profileViewModel.isGuest && profileViewModel.isCurrentUser(user)) {
                        Text(user.phone)
                            .font(.tabiBody)
                            .foregroundColor(.textGrey)
                    }
                }
            }
            Spacer()
        }
    }
}

#Preview {
    UserCard(user: UserData(name: "Testing", phone: "628123456789"))
}
