//
//  EventInviteCardView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts

struct EventInviteCardView: View {
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel

    var userData: UserData
    var isCurrentUser = false
    var isSelected: Bool = false
    
    var body: some View {
        VStack (spacing: 0) {
            Button {
                eventInviteViewModel.toggleSelectContact(user: userData)
            } label: {
                HStack {
                    HStack (spacing: .spacingSmall) {
                        UserAvatar(userData: userData)
                        VStack (alignment: .leading, spacing: .spacingXSmall) {
                            Text("\(userData.name)\(isCurrentUser ? " (You)" : "")")
                                .font(.tabiHeadline)
                                .foregroundStyle(.textBlack)
                            Text("\(userData.phone)")
                                .font(.tabiBody)
                                .foregroundStyle(.textGrey)
                        }
                    }
                    Spacer()
                    Circle()
                        .stroke(isCurrentUser ? .textGrey : (isSelected ? .buttonBlue : .textGrey), lineWidth: 1)
                        .fill(.clear)
                        .frame(width: 20)
                        .overlay {
                            if isSelected || isCurrentUser {
                                Icon(systemName: "checkmark.circle.fill", color: isCurrentUser ? .textGrey : .buttonBlue, size: 20)
                            }
                        }
                        .offset(x: -1)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                }
                .padding(.vertical, 12)
                .background(.clear)
                .contentShape(Rectangle())
            }
            .disabled(isCurrentUser)
        }
    }
}
