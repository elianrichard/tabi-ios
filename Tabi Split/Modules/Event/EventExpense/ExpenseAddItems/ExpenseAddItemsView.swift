//
//  ExpenseSplitView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI
import SwiftData

struct ExpenseAddItemsView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    
    var body: some View {
        VStack (alignment: .leading){
            CustomNavTitle(title: "Add Items")
            VStack (alignment: .leading, spacing: 10) {
                Text(eventExpenseViewModel.expenseName)
                    .font(.tabiTitle)
                HStack {
                    Image(systemName: "cylinder.split.1x2")
                        .font(.tabiBody)
                    Text("Custom Splitted")
                        .font(.tabiBody)
                }
                .padding([.bottom], 24)
            }
            ScrollView (showsIndicators: false) {
                VStack (alignment: .leading, spacing: 16) {
                    Text("Items")
                        .font(.tabiHeadline)
                    ForEach(Array(eventExpenseViewModel.items.enumerated()), id: \.offset) { index, item in
                        AddItemContainer(item: Bindable(eventExpenseViewModel).items[index], index: index)
                    }
                    
                    HStack{
                        CustomButton(text: "+ Add Item", type: .secondary) {
                            eventExpenseViewModel.createNewExpenseItem()
                        }
                        .frame(width: 108)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack (alignment: .leading, spacing: 16) {
                        Text("Additional Charge (optional)")
                            .font(.tabiHeadline)
                        VStack(alignment: .leading){
                            Text("Amount")
                                .font(.tabiBody)
                            ForEach(Array(eventExpenseViewModel.additionalCharges.enumerated()), id: \.offset) { index, item in
                                AdditionalChargeContainer(item: Bindable(eventExpenseViewModel).additionalCharges[index])
                            }
                        }
                        CustomButton(text: "+ Add more", type: .tertiary){
                            eventExpenseViewModel.additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: 0))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            ZStack{
                HStack(alignment: .top){
                    Text("Total Amount")
                        .font(.tabiBody)
                    Spacer()
                    Text("Rp\(eventExpenseViewModel.totalSpending.formatPrice())")
                        .font(.tabiBody)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 75)
                        .foregroundColor(.uiGray)
                        .offset(CGSize(width: 0, height: 12))
                )
                .offset(CGSize(width: 0, height: -40))
                    .zIndex(1)
                CustomButton(text: "Next", isEnabled: eventExpenseViewModel.items.map({$0.itemPrice}).reduce(0, +) != 0, customBackgroundColor: eventExpenseViewModel.items.map({$0.itemPrice}).reduce(0, +) != 0 ? .buttonBlue : .buttonGrey) {
                    routes.navigate(to: .ExpenseAssignView)
                }
                .zIndex(2)
            }
            .padding([.top], 36)
        }
        .padding()
        .background(.bgBlueElevated)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseAddItemsView()
        .environment(Routes())
        .environment(EventExpenseViewModel())
}
