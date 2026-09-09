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
    @Environment(Router.self) private var router
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel

    var body: some View {
        VStack (alignment: .leading){
            TopNavigation(title: "Add Items")
            ExpenseHeaderView()
            // Items came from a scanned receipt: the scan can misread things, so
            // prompt a check before moving on. Hidden when nothing was attached.
            if eventExpenseViewModel.hasReceipt {
                HStack(alignment: .top, spacing: .spacingXSmall) {
                    Icon(systemName: "exclamationmark.triangle.fill", color: .buttonYellow, size: 14)
                    Text("These items were read from your receipt. Please double-check the names, prices, and quantities before continuing.")
                        .font(.tabiBody2)
                        .foregroundStyle(.buttonYellow)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
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
                        .frame(width: 120)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack (alignment: .leading, spacing: 16) {
                        HStack(spacing: 0){
                            Text("Additional Charge ")
                                .font(.tabiBody)
                            Text("(optional)")
                                .font(.tabiBody)
                                .foregroundColor(.textGrey)
                        }
                        VStack(alignment: .leading){
                            ForEach(Array(eventExpenseViewModel.additionalCharges.enumerated()), id: \.offset) { index, item in
                                AdditionalChargeContainer(item: Bindable(eventExpenseViewModel).additionalCharges[index])
                            }
                        }
                        CustomButton(text: "+ Add More", type: .tertiary, vPadding: 0){
                            eventExpenseViewModel.additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: 0))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            ZStack{
                HStack(alignment: .top){
                    Text("Total")
                        .font(.tabiBody)
                    Spacer()
                    Text("Rp\(eventExpenseViewModel.totalSpending.formatPrice())")
                        .font(.tabiHeadline)
                }
                .padding(16)
                .background{
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.bgBlueElevated)
                        .stroke(.buttonBlueSelected, lineWidth: 1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 90)
                        .offset(CGSize(width: 0, height: 15))
                        .zIndex(1)
                }
                .offset(CGSize(width: 0, height: -50))
                    .zIndex(1)
                CustomButton(text: "Next", isEnabled: eventExpenseViewModel.items.map({$0.itemPrice}).reduce(0, +) != 0, customBackgroundColor: eventExpenseViewModel.items.map({$0.itemPrice}).reduce(0, +) != 0 ? .buttonBlue : .buttonGrey) {
                    router.push(.expenseAssign)
                }
                .zIndex(2)
            }
            .padding([.top], 60)
        }
        .padding()
        .background(.bgWhite)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseAddItemsView()
        .environment(Router())
        .environment(EventExpenseViewModel())
}
