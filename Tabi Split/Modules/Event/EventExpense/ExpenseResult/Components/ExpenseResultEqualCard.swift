//
//  ExpenseResultEqualCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 06/11/24.
//

import SwiftUI

struct ExpenseResultEqualCard: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    var person: UserData
    
    var body: some View {
        HStack {
            UserAvatar(userData: person)
            HStack {
                Text("\(person.name.getFirstName())'s")
                    .font(.tabiHeadline)
                if profileViewModel.isCurrentUser(person) {
                    Text("(Yours)")
                        .font(.tabiHeadline)
                        .foregroundStyle(.textGrey)
                }
            }
            Spacer()
            Text("Rp\(eventExpenseViewModel.calculateEqualSplit().formatPrice())")
                .font(.tabiHeadline)
        }
        .padding(.vertical, .spacingTight)
        .padding(.horizontal, .spacingMedium)
        .background(.bgWhite)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: .radiusMedium)
                .fill(.clear)
                .strokeBorder(.uiGray, lineWidth: 1)
        }
    }
}
