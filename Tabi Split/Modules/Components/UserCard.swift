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
    var isShowEmailText: Bool = true
    // When set, a trailing pencil button is shown that invokes this action. Callers
    // pass nil for cards that shouldn't be editable (e.g. the current user).
    var onEdit: (() -> Void)? = nil

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
                // Empty emails are already skipped, so a guest current user (who has
                // no email) shows no email row without a special case.
                if (isShowEmailText && user.email != "") {
                    Text(user.email)
                        .font(.tabiBody)
                        .foregroundColor(.textGrey)
                }
            }
            Spacer()
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    // Nugget-style chip (bordered, light fill) but a rounded
                    // rectangle instead of the full pill, holding a pencil icon.
                    Icon(systemName: "square.and.pencil", color: .buttonBlue, size: 16)
                        .padding(.spacingSmall)
                }
            }
        }
    }
}

#Preview {
    UserCard(user: UserData(name: "Testing", email: "test@example.com"))
}
