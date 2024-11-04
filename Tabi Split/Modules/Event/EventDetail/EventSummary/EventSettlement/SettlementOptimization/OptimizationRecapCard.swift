//
//  OptimizationRecapCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct OptimizationRecapCard: View {
    var isLast: Bool = false
    var recapData: OptimizationRecapData
    
    var isHighlight: Bool {
        return recapData.recipient.name == "You" || recapData.sender.name == "You"
    }
    
    var highlightColor: Color {
        if (recapData.recipient.name == "You") {
            return .highlightGreen
        } else if (recapData.sender.name == "You") {
            return .highlightRed
        } else { return .clear }
    }
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            UserAvatar(userData: recapData.sender)
            HStack (spacing: .spacingSmall) {
                Text("\(recapData.sender.name.getFirstName())")
                    .font(recapData.sender.name == "You" ? .tabiBodyBold : .tabiBody)
                Icon(systemName: "arrow.right", size: 12)
                Text("\(recapData.recipient.name.getFirstName())")
                    .font(recapData.recipient.name == "You" ? .tabiBodyBold : .tabiBody)
            }
            Spacer()
            Text("Rp\(recapData.amount.formatPrice())")
                .padding(.horizontal, .spacingTight)
                .padding(.vertical, .spacingXSmall)
                .background(highlightColor)
                .clipShape(RoundedRectangle(cornerRadius: .spacingTight))
        }
    }
}

#Preview {
    OptimizationRecapCard(recapData: OptimizationRecapData(sender: UserData(name: "Dharma", phone: "Phone"), recipient: UserData(name: "You", phone: "Phone"), amount: 50_000))
}
