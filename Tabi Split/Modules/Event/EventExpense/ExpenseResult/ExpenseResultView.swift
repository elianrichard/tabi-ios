//
//  ExpenseResultView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 08/10/24.
//

import Foundation
import SwiftUI

struct ExpenseResultView: View {
    @Environment(Routes.self) var routes
    @Environment(EventExpenseViewModel.self) var eventExpenseViewModel
    @Environment(EventViewModel.self) var eventViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                HStack {
                    TopNavigation(title: "Expense Result")
                    Spacer()
                    if eventExpenseViewModel.selectedExpense != nil && !eventExpenseViewModel.isEdit {
                        Menu {
                            Button("Edit Expense") {
                                eventExpenseViewModel.isEdit = true
                                routes.navigate(to: .AddExpenseView)
                            }
                            Button("Delete Expense") {
                                if let event = eventViewModel.selectedEvent {
                                    eventExpenseViewModel.handleDeleteExpense(event)
                                    routes.navigateBack()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.black)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
            }
            VStack (alignment: .leading, spacing: 12) {
                Text(eventExpenseViewModel.expenseName)
                    .font(.tabiTitle)
                HStack {
                    Image(systemName: "cylinder.split.1x2")
                    Text(eventExpenseViewModel.selectedMethod?.splitDescription ?? "unknown")
                        .font(.tabiBody)
                }
            }
            .padding([.bottom], 24)
            ScrollView(showsIndicators: false){
                if eventExpenseViewModel.selectedMethod == .equally {
                    ForEach(eventExpenseViewModel.selectedParticipants){ person in
                        HStack{
                            Circle()
                                .frame(width: 40, height: 40)
                            Text("\(person.name.getFirstName())'s Expense")
                                .font(.tabiHeadline)
                            Spacer()
                            Text("Rp")
                                .font(.tabiHeadline)
                            Text(eventExpenseViewModel.calculateEqualSplit().formatPrice())
                                .font(.tabiHeadline)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(.bgWhite)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.clear)
                                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                        .cornerRadius(16)
                    }
                } else if eventExpenseViewModel.selectedMethod == .custom {
                    ForEach(eventExpenseViewModel.peopleItems) { person in
                        VStack {
                            HStack {
                                Circle()
                                    .frame(width: 40, height: 40)
                                Text(person.name.getFirstName())
                                    .font(.tabiHeadline)
                                Spacer()
                                Text("Rp \(eventExpenseViewModel.calculatePersonSpending(person: person).formatPrice())")
                                    .font(.tabiHeadline)
                            }
                            Divider()
                                .padding(.vertical, 6)
                            ForEach (person.items) { item in
                                HStack(alignment: .top){
                                    Text(item.itemName)
                                        .font(.tabiHeadline)
                                    Spacer()
                                    Text("x" + String(item.itemQuantity.formatted(.number)))
                                        .font(.tabiBody)
                                    Text("Rp \((Float(item.itemQuantity) * item.itemPrice).formatPrice())")
                                        .frame(width: 100, alignment: .trailing)
                                        .lineLimit(1)
                                        .font(.tabiBody)
                                }
                            }
                            
                            DisclosureGroup() {
                                Divider()
                                    .padding(6)
                                ForEach(person.additional) { additionalItem in
                                    HStack {
                                        Text((AdditionalChargeType(rawValue: additionalItem.additionalChargeType) ?? .other).name)
                                        Spacer()
                                        Text("Rp \(additionalItem.amount.formatPrice())")
                                    }
                                    .font(.subheadline)
                                }
                            } label: {
                                HStack {
                                    Text("See Details")
                                        .font(.tabiBody)
                                }
                            }
                            .accentColor(.black)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(.bgWhite)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.clear)
                                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                        .cornerRadius(16)
                    }
                }
            }
            if eventExpenseViewModel.selectedExpense == nil {
                CustomButton(text: "Save Expense") {
                    if let event = eventViewModel.selectedEvent {
                        eventExpenseViewModel.finalizeExpense(event)
                        routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
                    }
                }
            } else {
                if eventExpenseViewModel.isEdit {
                    CustomButton(text: "Save Expense") {
                        if let event = eventViewModel.selectedEvent {
                            eventExpenseViewModel.handleUpdateExpense(event)
                            eventExpenseViewModel.isEdit = false
                            routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
                        }
                    }
                } else {
                    CustomButton(text: "Done") {
                        print("Check Receipt")
                    }
                }
            }
        }
        .padding()
        .background(.bgBlueElevated)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseResultView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
