//
//  OptimizationPersonCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct OptimizationPersonCard: View {
    var data: OptimizationPersonData
    var body: some View {
        VStack (alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(.gray)
                    .frame(width: 40)
                Text("\(data.name)")
                Spacer()
            }
            HStack (spacing: 20) {
                VStack (alignment: .leading, spacing: 8) {
                    Text("Total Debt")
                    Text("Rp \(data.debtAmount.formatPrice())")
                        .foregroundStyle(.red)
                }
                VStack (alignment: .leading, spacing: 8) {
                    Text("Total Lent")
                    Text("Rp \(data.lentAmount.formatPrice())")
                        .foregroundStyle(.green)
                }
            }
            VStack (alignment: .leading) {
                Text("Balance")
                Text("\(data.lentAmount < data.debtAmount ? "+" : "-") Rp \((data.lentAmount - data.debtAmount).formatPrice(isShowSign: false))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(UIColor(hex: data.lentAmount < data.debtAmount ? "#D4FFDA" : "#FBD0DA")))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
//            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color(UIColor(hex: "#C9C9C9")), lineWidth: 1)
        }
        .padding(1)
    }
}

#Preview {
    OptimizationPersonCard(data: OptimizationPersonData(name: "Elian", debtAmount: 10_000, lentAmount: 50_000))
}
