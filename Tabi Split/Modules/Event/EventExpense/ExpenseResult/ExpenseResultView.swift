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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                Text("Add Items")
                    .font(.title2)
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
                        .background(Color(.midLightGray))
                        .cornerRadius(20)
                    }
                } else if eventExpenseViewModel.selectedMethod == .custom {
                    ForEach(eventExpenseViewModel.peopleItems) { person in
                        VStack {
                            HStack {
                                Circle()
                                    .frame(width: 40, height: 40)
                                Text(person.name)
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
                        .background(Color(.midLightGray))
                        .cornerRadius(10)
                    }
                }
            }
            BottomButton(text: "Done")
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseResultView()
        .environment(Routes())
        .environment(EventExpenseViewModel())
}
