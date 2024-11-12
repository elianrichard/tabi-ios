//
//  EventTotalsSummaryCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummarySpendingCard: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    var text: String
    var amount: Float
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            UserAvatar(userData: profileViewModel.user)
            VStack (alignment: .leading, spacing: .spacingXSmall) {
                Text(text)
                    .font(.tabiBody)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                Text("Rp\(amount.formatPrice())")
                    .font(.tabiSubtitle)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.spacingTight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.uiGray, lineWidth: 1)
        }
    }
}

#Preview {
    EventSummarySpendingCard(text: "Your total spending", amount: 790000)
        .environment(ProfileViewModel())
}
