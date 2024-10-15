//
//  EventDetailCard.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailCardView : View {
    var expense: Expense
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel

    var body : some View {
        HStack (alignment: .top) {
            HStack (alignment: .top, spacing: 16) {
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 40)
                VStack (alignment: .leading, spacing: 4) {
                    Text("\(expense.name.capitalized)")
                        .font(.body)
                    Text("\(expense.coverer.name.getFirstName().capitalized) paid this bill")
                        .foregroundStyle(.black.opacity(0.5))
                        .font(.subheadline)
                }
            }
            Spacer()
            VStack (alignment: .trailing) {
                Text("Rp \(String(format: "%.0f", expense.price).formatPrice())")
                Text("\(expense.dateOfCreation.toProperText())")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(UIColor(hex: "#EBEBEB")))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            eventExpenseViewModel.resetViewModel()
            if let event = eventViewModel.selectedEvent {
                guard let expenseIndex = event.expenses.firstIndex(where: { $0 == expense }) else { return }
                eventExpenseViewModel.selectedExpense = event.expenses[expenseIndex]
                routes.navigate(to: .ExpenseResultView)
            }
        }
    }
}

#Preview {
    EventDetailCardView(expense:
                            Expense(name: "Sate", coverer: UserData(name: "Naufal", phone: "08123456789"), dateOfCreation: Date(), price: 100000, splitMethod: .equally))
    .environment(Routes())
    .environment(EventExpenseViewModel())
}
