//
//  QuantityChangeView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 22/10/24.
//

import Foundation
import SwiftUI

struct QuantityChangeView: View {
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Binding var item: ExpenseItem
    @Binding var close: Bool
    
    var body: some View {
        VStack(alignment: .leading){
            Text(item.itemName)
                .font(.title)
                .fontWeight(.bold)
            Text("Quantity: " + String(item.itemQuantity.formatted(.number)))
                .padding(.bottom, 24)
            ScrollView(){
                VStack{
                    ForEach(Array(item.assignees.enumerated()), id: \.offset) { (index, assignee) in
                        HStack(alignment: .center){
                            Circle()
                                .frame(width: 40, height: 40)
                                .padding([.trailing], 12)
                            Text(assignee.user.name)
                            Spacer()
                            HStack{
                                QuantityCounter(quantity: Bindable(assignee).share, letZero: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(.bgWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.lightGray), lineWidth: 0.5)
                                .padding(0.5)
                        )
                    }
                }
            }
            CustomButton(text: "Save") {
                close.toggle()
            }
        }
        .onDisappear{
            eventExpenseViewModel.removeZeroShareAssignee(item: item)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .padding([.top], 10)
    }
}

#Preview {
    QuantityChangeView(item: .constant(ExpenseItem(itemName: "Teh tarik", itemPrice: 10000, itemQuantity: 10, assignees: [ExpensePerson(user: UserData(name: "Darma", phone: ""), share: 1), ExpensePerson(user: UserData(name: "Eko", phone: ""), share: 2)])), close: .constant(true))
        .environment(EventExpenseViewModel())
}
