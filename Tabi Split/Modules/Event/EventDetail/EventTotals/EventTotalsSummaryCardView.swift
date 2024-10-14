//
//  EventTotalsSummaryCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventTotalsSummaryCardView: View {
    var text: String
    var amount: Double
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack (alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 40)
                Text(text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            Text("Rp \(String(format: "%.0f", amount).formatPrice())")
                .font(.title2)
                .fontWeight(.medium)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: 110, alignment: .topLeading)
        .background(Color(UIColor(hex: "#EBEBEB")))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    EventTotalsSummaryCardView(text: "Total Group Spending", amount: 790000)
}
