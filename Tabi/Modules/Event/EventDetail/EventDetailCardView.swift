//
//  EventDetailCard.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailCardView : View {
    var body : some View {
        HStack {
            HStack (spacing: 16) {
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 40)
                VStack (alignment: .leading, spacing: 4) {
                    Text("Breakfast")
                        .font(.body)
                    Text("Naufal Paid this bill")
                        .foregroundStyle(.black.opacity(0.5))
                        .font(.subheadline)
                }
            }
            Spacer()
            VStack (alignment: .trailing) {
                Text("Rp 100.000")
                Text("Today")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(UIColor(hex: "#EBEBEB")))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    EventDetailCardView()
}
