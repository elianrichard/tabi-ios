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
        VStack (alignment: .leading, spacing: 24){
            ZStack {
                Text("Add Items")
                    .font(.title2)
                HStack {
                    Button {
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
                    Text("Custom Splitted")
                }
            }
            ScrollView (showsIndicators: false) {
                VStack (alignment: .leading, spacing: 18) {
                    Text("Items")
                        .font(.title2)
                    ForEach(Array(eventExpenseViewModel.items.enumerated()), id: \.offset) { index, item in
                        AddItemContainer(item: Bindable(eventExpenseViewModel).items[index], index: index)
                    }
                    Button {
                        eventExpenseViewModel.createNewExpenseItem()
                    } label: {
                        Text("+ Add Item")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color(.lightGray))
                            .cornerRadius(50)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Divider()
                    
                    VStack (alignment: .leading) {
                        Text("Additional Charge (optional)")
                            .font(.title3)
                            .padding([.bottom], 10)
                        Text("Amount")
                        ForEach(Array(eventExpenseViewModel.additionalCharges.enumerated()), id: \.offset) { index, item in
                            AdditionalChargeContainer(item: Bindable(eventExpenseViewModel).additionalCharges[index], index: index)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button{
                        eventExpenseViewModel.additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: 0))
                    } label: {
                        Text("+ Add more")
                            .padding()
                            .foregroundColor(.black)
                    }
                }
            }
            HStack{
                Text("Total Bill")
                    .fontWeight(.heavy)
                Spacer()
                Text("Rp \(eventExpenseViewModel.totalSpending.formatPrice())")
                    .fontWeight(.heavy)
            }
            Button {
                routes.navigate(to: .ExpenseAssignView)
            } label: {
                BottomButton(text: "Next")
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseAddItemsView()
        .environment(Routes())
        .environment(EventExpenseViewModel())
}
