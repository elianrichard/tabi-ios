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
        VStack (alignment: .leading) {
            Circle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(width: 40)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            Text(text)
                .font(.body)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Rp \(String(format: "%.0f", amount).formatPrice())")
                .font(.title2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .center)

        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: 130, alignment: .center)
        .background(Color(UIColor(hex: "#EBEBEB")))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    EventSummarySpendingCard(text: "Total Group Spending", amount: 790000)
}
