//
//  PaymentMethodCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct PaymentMethodCard: View {
//    var name: String
//    var bankName: String
//    var bankNumber: String
    var payment: PaymentMethod
    var isLast = false
    
    var body: some View {
        HStack (spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(width: 70, height: 70)
            VStack (alignment: .leading) {
                Text("\(payment.name)")
                    .fontWeight(.medium)
                    .font(.title3)
                VStack (alignment: .leading) {
                    Text("\(payment.bankName)")
                    Text("\(payment.bankNumber)")
                }
                .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button {
                print("copy")
            } label: {
                Image(systemName: "document.on.document")
                    .font(.title2)
            }
        }
        .padding(.vertical)
        .border(width: isLast ? 0 : 1, edges: [.bottom], color: Color(UIColor(hex: "#D9D9D9")))
    }
}

#Preview {
    PaymentMethodCard(payment: PaymentMethod(name: "Elian", bankName: "Bank BCA", bankNumber: "000123456789"), isLast: true)
}
