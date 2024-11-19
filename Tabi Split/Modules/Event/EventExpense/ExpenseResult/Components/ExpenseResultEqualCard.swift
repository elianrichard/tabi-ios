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
    @Environment(ProfileViewModel.self) private var profileViewModel
    var person: UserData
    
    var body: some View {
        HStack {
            UserAvatar(userData: person)
            HStack(spacing: 0){
                Text("\(person.name.getFirstName())'s")
                    .font(.tabiHeadline)
                if profileViewModel.user == person {
                    Text(" (Yours)")
                        .font(.tabiBody)
                        .foregroundColor(.textGrey)
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
