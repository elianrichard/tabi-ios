//
//  EventTotalsOptimizationCardView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryHistoryCard : View {
    var data: SummaryHistoryData
    @Environment(Router.self) private var router
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel

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
                    .background(data.amount > 0 ? Color(UIColor(hex: "#D4FFDA")) : Color(UIColor(hex: "#FBD0DA")))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            VStack (alignment: .trailing, spacing: 4) {
                Text(data.expenseDate.toProperText())
                    .font(.tabiBody)
                    .foregroundStyle(.textGrey)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.uiGray, lineWidth: 1)
        }
        .padding(1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let expense = data.expense else { return }
            eventExpenseViewModel.selectedExpense = expense
            router.push(.expenseResult)
        }
    }
}

#Preview {
    EventSummaryHistoryCard(data: SummaryHistoryData(expenseName: "KFC", expenseDate: Date(), amount: 50_000))
        .environment(Router())
        .environment(EventExpenseViewModel())
}
