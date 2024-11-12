//
//  OptimizationPersonCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct OptimizationPersonCard: View {
    var data: PersonBalanceData
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
                    Text("Rp\(data.lent.formatPrice())")
                        .foregroundStyle(.buttonGreen)
                        .font(.tabiBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack (alignment: .leading, spacing: .spacingSmall) {
                    Text("Total Debt")
                        .font(.tabiBody)
                    Text("Rp\(data.debt.formatPrice())")
                        .foregroundStyle(.buttonRed)
                        .font(.tabiBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack (alignment: .leading, spacing: .spacingXSmall) {
                Text(data.lent < data.debt ? "Should pay" : "Should recieve")
                    .font(.tabiHeadline)
                Text("Rp\((data.lent - data.debt).formatPrice(isShowSign: false))")
                    .font(.tabiSubtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(data.lent < data.debt ? Color.highlightRed : Color.highlightGreen)
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
