//
//  EventDetailCard.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailExpenseCard : View {
    var expense: Expense
    @Environment(Routes.self) private var routes
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel

    var body : some View {
        HStack (alignment: .top) {
            HStack (alignment: .center, spacing: 16) {
                Image(.sampleExpenseCard)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                VStack (alignment: .leading, spacing: 4) {
                    Text("\(expense.name.capitalized)")
                        .font(.tabiHeadline)
                    Text("\(expense.coverer.name.getFirstName().capitalized) paid this bill")
                        .foregroundStyle(.textGrey)
                        .font(.tabiBody)
                }
            }
            Spacer()
            VStack (alignment: .trailing, spacing: 4) {
                Text("Rp\(expense.price.formatPrice())")
                    .font(.tabiHeadline)
                    .foregroundStyle(.textBlack)
                Text("\(expense.dateOfCreation.toProperText())")
                    .font(.tabiBody)
                    .foregroundStyle(.textGrey)
            }
        }
        .frame(maxWidth: .infinity)
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
            eventExpenseViewModel.selectedExpense = expense
            routes.navigate(to: .ExpenseResultView)
        }
    }
}

#Preview {
    EventDetailExpenseCard(expense:
                            Expense(name: "Kain Tenun Jepara", coverer: UserData(name: "Naufal", phone: "08123456789"), dateOfCreation: Date(), price: 100000, splitMethod: .equally))
    .environment(Routes())
    .environment(EventExpenseViewModel())
}
