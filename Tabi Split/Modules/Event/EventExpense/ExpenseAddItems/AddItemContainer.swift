//
//  AddItemContainer.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI
import Combine

struct AddItemContainer: View {
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Binding var item: ExpenseItem
    @State var price: String = ""
    var index: Int
    
    var body: some View {
        VStack{
            VStack(alignment: .leading){
                HStack{
                    Text("Item " + String(index + 1))
                    Spacer()
                    Image(systemName: "trash")
                        .onTapGesture {
                            eventExpenseViewModel.deleteItem(item: item)
                            eventExpenseViewModel.calculateTotal()
                        }
                }
                Divider()
                VStack(alignment: .leading){
                    Text("Name")
                        .padding([.top, .bottom], 5)
                    TextField("Item Name", text: Bindable(item).itemName)
                        .padding(10)
                        .background(.uiGray)
                        .cornerRadius(5)
                } // Title
                VStack(alignment: .leading){
                    Text("Price")
                        .padding([.top, .bottom], 5)
                    HStack{
                        Text("Rp")
                        TextField("10.000", text: $price)
                            .keyboardType(.numberPad)
                            .onChange(of: price) {
                                price = price.formatPrice()
                                item.itemPrice = Float(price.removeDots()) ?? 0
                                eventExpenseViewModel.calculateTotal()
                            }
                            .padding(10)
                            .background(.uiGray)
                            .cornerRadius(5)
                    }
                    .onReceive(Just(item.itemPrice)) { _ in
                        price = item.itemPrice != 0 ? String(item.itemPrice.formatPrice()) : ""
                    }
                    VStack(alignment: .leading){
                        Text("Quantity")
                            .padding([.top, .bottom], 5)
                        HStack{
                            Text("-")
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(item.itemQuantity != 1 ? Color(.lightGray) : .uiGray)
                                )
                                .onTapGesture {
                                    item.itemQuantity-=1
                                    eventExpenseViewModel.calculateTotal()
                                }
                                .disabled(item.itemQuantity == 1 ? true : false)
                            Text(String(item.itemQuantity.formatted(.number)))
                                .padding([.leading, .trailing], 10)
                            Text("+")
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.lightGray))
                                )
                                .onTapGesture {
                                    item.itemQuantity+=1
                                    eventExpenseViewModel.calculateTotal()
                                }
                        }
                        .padding(10)
                    }
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.lightGray), lineWidth: 1)
            )
        }
    }
}
