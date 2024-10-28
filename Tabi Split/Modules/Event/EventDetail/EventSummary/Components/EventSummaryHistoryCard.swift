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
    var isLast: Bool = false
    
    var body : some View {
        HStack (alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(width: 40)
                .frame(maxHeight: .infinity, alignment: .center)
            VStack (alignment: .leading, spacing: 4) {
                Text(itemName)
                Text("Rp \(String(format: "%.0f", amount).formatPrice())")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(amount > 0 ? Color(UIColor(hex: "#D4FFDA")) : Color(UIColor(hex: "#FBD0DA")))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            Text(date.toProperText())
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical, 6)
        
        if (isLast == false) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(hex: "#D9D9D9")))
        }
    }
}

#Preview {
    EventSummaryHistoryCard(itemName: "KFC", amount: 500_000, date: Date())
}
