//
//  EventTotalsOptimizationCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryHistoryCard : View {
    var itemName: String
    var amount: Double
    var date: Date
    
    var body : some View {
        HStack (alignment: .top, spacing: 12)  {
            Image(.sampleExpenseCard)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack (alignment: .leading, spacing: 4) {
                Text(itemName)
                    .font(.tabiHeadline)
                Text("\(amount < 0 ? "- " : "")Rp \(String(format: "%.0f", abs(amount)).formatPrice())")
                    .font(.tabiHeadline)
                    .fontWeight(.medium)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(amount > 0 ? Color(UIColor(hex: "#D4FFDA")) : Color(UIColor(hex: "#FBD0DA")))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            Text(date.toProperText())
                .font(.tabiBody)
                .foregroundStyle(.textGrey)
        }
        .padding(.vertical, .spacingSmall)
    }
}

#Preview {
    EventSummaryHistoryCard(itemName: "KFC", amount: 500_000, date: Date())
}
