//
//  EventTotalsOptimizationCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryHistoryCard : View {    
    var data: SummaryHistoryData
    
    var body : some View {
        HStack (alignment: .top, spacing: 12)  {
            Image(.sampleExpenseCard)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack (alignment: .leading, spacing: 4) {
                Text(data.expenseName)
                    .font(.tabiHeadline)
                Text("\(data.amount < 0 ? "- " : "")Rp\(data.amount.formatPrice(isShowSign: false))")
                    .font(.tabiHeadline)
                    .fontWeight(.medium)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(data.amount > 0 ? Color(.highlightGreen) : Color(.highlightRed))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            Text(data.expenseDate.toProperText())
                .font(.tabiBody)
                .foregroundStyle(.textGrey)
        }
        .padding(.vertical, .spacingSmall)
    }
}

#Preview {
    EventSummaryHistoryCard(data: SummaryHistoryData(expenseName: "KFC", expenseDate: Date(), amount: 50_000))
}
