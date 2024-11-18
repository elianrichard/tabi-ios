//
//  OptimizationRecapCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct OptimizationRecapCard: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    var isLast: Bool = false
    var recapData: PersonBalanceData
    
    var body: some View {
        ForEach(recapData.settlement) { settlement in
            HStack (spacing: .spacingTight) {
                UserAvatar(userData: recapData.user)
                HStack (spacing: .spacingSmall) {
                    Text("\(recapData.user.name.getFirstName())")
                        .font(isTextBold(user: recapData.user))
                    Icon(systemName: "arrow.right", size: 12)
                    Text("\(settlement.userPaid.name.getFirstName())")
                        .font(isTextBold(user: settlement.userPaid))
                }
                Spacer()
                Text("Rp\(settlement.amount.formatPrice())")
                    .font(.tabiBody)
                    .padding(.horizontal, .spacingTight)
                    .padding(.vertical, .spacingXSmall)
                    .background(getHighlightColor(userDebt: recapData.user, userLent: settlement.userPaid))
                    .clipShape(RoundedRectangle(cornerRadius: .spacingTight))
            }
        }
    }
    
    private func getHighlightColor (userDebt: UserData, userLent: UserData) -> Color {
        if (profileViewModel.isCurrentUser(userLent)) {
            return .highlightGreen
        } else if (profileViewModel.isCurrentUser(userDebt)) {
            return .highlightRed
        }
        return .clear
    }
    
    private func isTextBold (user: UserData) -> Font {
        if profileViewModel.isCurrentUser(user) {
            return .tabiBodyBold
        } else { return .tabiBody }
    }
}
