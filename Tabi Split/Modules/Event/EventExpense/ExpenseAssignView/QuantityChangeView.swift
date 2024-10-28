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
            ScrollView(){
                ForEach(Array(item.assignees.enumerated()), id: \.offset) { (index, assignee) in
                    HStack(alignment: .center){
                        Circle()
                            .frame(width: 40, height: 40)
                            .padding([.trailing], 12)
                        Text(assignee.user.name)
                        Spacer()
                        QuantityCounter(quantity: Bindable(assignee).share, letZero: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .bottom], 5)
                    .padding([.trailing, .leading], 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.lightGray), lineWidth: 1)
                    )
                }
            }
            BottomButton(text: "Save")
                .onTapGesture {
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
