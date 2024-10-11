//
//  EventTotalsOptimizationCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventTotalsOptimizationCardView : View {
    var payorName: String
    var recipientName: String
    var amount: Double
    var isLast: Bool = false
    
    var body : some View {
        HStack (spacing: 12) {
            Circle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(width: 40)
            VStack (alignment: .leading, spacing: 4) {
                HStack (spacing: 4) {
                    Text(payorName)
                        .fontWeight(payorName == "You" ? .medium : .regular)
                    Image(systemName: "arrow.forward")
                    Text(recipientName)
                        .fontWeight(recipientName == "You" ? .medium : .regular)
                }
                Text("Rp \(String(format: "%.0f", amount).formatPrice())")
                    .font(.headline)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical, 20)
        
        if (isLast == false) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(hex: "#D9D9D9")))
        }
    }
}

#Preview {
    EventTotalsOptimizationCardView(payorName: "Naufal", recipientName: "You", amount: 500_000)
}
