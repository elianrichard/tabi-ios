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
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                HStack {
                    HStack {
                        Button {
                            eventExpenseViewModel.peopleItems = []
                            routes.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            VStack (alignment: .leading, spacing: 10) {
                Text(eventExpenseViewModel.expenseName)
                    .font(.title)
                HStack {
                    Image(systemName: "cylinder.split.1x2")
                    Text(eventExpenseViewModel.selectedMethod?.splitDescription ?? "unknown")
                }
            }
            ScrollView{
                if eventExpenseViewModel.selectedMethod == .equally {
                    ForEach(eventExpenseViewModel.selectedParticipants){ person in
                        HStack{
                            Circle()
                                .frame(width: 40, height: 40)
                            Text("\(person.name.getFirstName())'s Expense")
                            Spacer()
                            Text("Rp")
                                .font(.title2)
                            Text(eventExpenseViewModel.calculateEqualSplit().formatPrice())
                                .font(.title2)
                        }
                        .padding()
                        .background(.uiGray)
                        .cornerRadius(20)
                    }
                } else if eventExpenseViewModel.selectedMethod == .custom {
                    ForEach(eventExpenseViewModel.peopleItems) { person in
                        VStack {
                            HStack {
                                Circle()
                                    .frame(width: 40, height: 40)
                                Text(person.name.getFirstName())
                                    .font(.title3)
                                Spacer()
                                Text("Rp \(eventExpenseViewModel.calculatePersonSpending(person: person).formatPrice())")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Divider()
                            ForEach (person.items) { item in
                                HStack(alignment: .top){
                                    Text(item.itemName)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("x" + String(item.itemQuantity))
                                        .font(.subheadline)
                                    Text("Rp \((Float(item.itemQuantity) * item.itemPrice).formatPrice())")
                                        .frame(width: 100, alignment: .trailing)
                                        .lineLimit(1)
                                        .font(.subheadline)
                                }
                            }
                            
                            DisclosureGroup() {
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
                                    Text("Bill Details")
                                        .font(.headline)
                                        .padding(.vertical, 5)
                                }
                            }
                        }
                        .padding()
                        .background(.uiGray)
                        .cornerRadius(10)
                    }
                }
            }
            if eventExpenseViewModel.selectedExpense == nil {
                Button {
                    if let event = eventViewModel.selectedEvent {
                        eventExpenseViewModel.finalizeExpense(event)
                        routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
                    }
                } label: {
                    BottomButton(text: "Done")
                }
            } else {
                if eventExpenseViewModel.isEdit {
                    Button {
                        if let event = eventViewModel.selectedEvent {
                            eventExpenseViewModel.handleUpdateExpense(event)
                            eventExpenseViewModel.isEdit = false
                            routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
                        }
                    } label: {
                        BottomButton(text: "Done")
                    }
                } else {
                    Button {
                        print("Check Receipt")
                    } label: {
                        BottomButton(text: "Check Receipt")
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseResultView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
