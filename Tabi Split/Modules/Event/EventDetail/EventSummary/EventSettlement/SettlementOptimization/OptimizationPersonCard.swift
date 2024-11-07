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
        VStack (alignment: .leading, spacing: .spacingRegular) {
            HStack (spacing: .spacingTight) {
                UserAvatar(userData: data.user, namePosition: .right)
                Spacer()
            }
            HStack (spacing: .spacingMedium) {
                VStack (alignment: .leading, spacing: .spacingSmall) {
                    Text("Total Lent")
                        .font(.tabiBody)
                    Text("Rp\(data.lentAmount.formatPrice())")
                        .foregroundStyle(.buttonGreen)
                        .font(.tabiBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack (alignment: .leading, spacing: .spacingSmall) {
                    Text("Total Debt")
                        .font(.tabiBody)
                    Text("Rp\(data.debtAmount.formatPrice())")
                        .foregroundStyle(.buttonRed)
                        .font(.tabiBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack (alignment: .leading, spacing: .spacingXSmall) {
                Text(data.lentAmount < data.debtAmount ? "Should pay" : "Should recieve")
                    .font(.tabiHeadline)
                Text("Rp\((data.lentAmount - data.debtAmount).formatPrice(isShowSign: false))")
                    .font(.tabiSubtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(data.lentAmount < data.debtAmount ? Color.highlightRed : Color.highlightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSmall))
            }
        }
        .padding(.vertical, .spacingTight)
        .padding(.horizontal, .spacingMedium)
        .frame(width: 300)
        .overlay {
            RoundedRectangle(cornerRadius: .radiusLarge)
                .strokeBorder(.uiGray, lineWidth: 1)
                .padding(1)
        }
    }
}

#Preview {
    OptimizationPersonCard(data: OptimizationPersonData(user: UserData(name: "Elian", phone: "Phone"), debtAmount: 10_000, lentAmount: 50_000))
}
