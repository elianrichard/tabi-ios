//
//  EventTotalsView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventTotalsView: View {
    var body: some View {
        VStack (spacing: 18) {
            HStack (alignment: .top, spacing: 12) {
                EventTotalsSummaryCardView(text: "Total Group Spending", amount: 790_000)
                EventTotalsSummaryCardView(text: "Total Personal Spending", amount: 280_000)
            }
            VStack (spacing: 16) {
                HStack {
                    Text("Optimization Result")
                    Spacer()
                    Button {
                        print("see details page")
                    } label: {
                        Text("See Details")
                            .font(.caption)
                            .underline(true)
                            .foregroundStyle(.black)
                    }
                }
                ScrollView (showsIndicators: false) {
                    VStack (spacing: 0) {
                        EventTotalsOptimizationCardView(payorName: "Naufal", recipientName: "You", amount: 500000)
                        EventTotalsOptimizationCardView(payorName: "Naufal", recipientName: "Elian", amount: 500000)
                        EventTotalsOptimizationCardView(payorName: "You", recipientName: "Darma", amount: 500000)
                        EventTotalsOptimizationCardView(payorName: "Vina", recipientName: "Darma", amount: 500000)
                        EventTotalsOptimizationCardView(payorName: "Darma", recipientName: "Elian", amount: 500000, isLast: true)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding([.top, .leading, .trailing], 16)
            .background(Color(UIColor(hex: "#F7F7F7")))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

#Preview {
    EventTotalsView()
}
