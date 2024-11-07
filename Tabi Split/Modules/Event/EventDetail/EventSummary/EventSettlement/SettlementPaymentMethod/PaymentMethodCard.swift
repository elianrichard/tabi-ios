//
//  PaymentMethodCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct PaymentMethodCard: View {
    var payment: PaymentMethod
    var isLast = false
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            Image(uiImage: payment.bank.bankLogo)
                .resizable()
                .scaledToFit()
                .padding(.spacingXSmall)
                .frame(width: 60, height: 60)
                .overlay {
                    RoundedRectangle(cornerRadius: .radiusSmall)
                        .strokeBorder(.uiGray, lineWidth: 1)
                        .padding(1)
                }
            VStack (alignment: .leading, spacing: .spacingXSmall) {
                Text("\(payment.name)")
                    .font(.tabiHeadline)
                VStack (alignment: .leading, spacing: 0) {
                    Text("\(payment.bank.bankName)")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                    Text("\(payment.bankNumber)")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                }
                .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button {
                UIPasteboard.general.setValue("\(payment.bankNumber)", forPasteboardType: UTType.plainText.identifier)
            } label: {
                Icon(.copyIcon, color: .textBlue, size: 24)
            }
        }
        .padding(.vertical, .spacingTight)
        .border(width: isLast ? 0 : 1, edges: [.bottom], color: .uiGray)
    }
}

#Preview {
    PaymentMethodCard(payment: PaymentMethod(name: "Elian", bank: .bca, bankNumber: "000123456789"), isLast: true)
}
