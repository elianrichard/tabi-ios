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
        return recapData.recipient == "You" || recapData.sender == "You"
    }
    
    var highlightColor: Color {
        if (recapData.recipient == "You") {
            return Color(UIColor(hex: "#D4FFDA"))
        } else if (recapData.sender == "You") {
            return Color(UIColor(hex: "#FBD0DA"))
        } else { return .clear }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(UIColor(hex: "#C9C9C9")))
                .frame(width: 40)
            HStack {
                Text("\(recapData.sender)")
                    .fontWeight(recapData.sender == "You" ? .medium : .regular)
                Image(systemName: "arrow.right")
                Text("\(recapData.recipient)")
                    .fontWeight(recapData.recipient == "You" ? .medium : .regular)
            }
            Spacer()
            Text("Rp \(recapData.amount.formatPrice())")
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(highlightColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.vertical)
        .border(width: isLast ? 0 : 1, edges: [.bottom], color: Color(UIColor(hex: "#C9C9C9")))
    }
}

#Preview {
    OptimizationRecapCard(recapData: OptimizationRecapData(sender: "Naufal", recipient: "You", amount: 50_000))
}
