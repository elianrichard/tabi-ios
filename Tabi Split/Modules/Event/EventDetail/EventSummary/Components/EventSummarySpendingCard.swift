//
//  EventTotalsSummaryCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummarySpendingCard: View {
    var text: String
    var amount: Double
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            Image(.samplePersonProfile1)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack (alignment: .leading, spacing: .spacingXSmall) {
                Text(text)
                    .font(.tabiBody)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                Text("Rp\(String(format: "%.0f", amount).formatPrice())")
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
}
