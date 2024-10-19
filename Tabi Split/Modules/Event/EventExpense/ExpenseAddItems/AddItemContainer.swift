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
    @State var item: ExpenseItem
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
                        }
                }
                Divider()
                VStack(alignment: .leading){
                    Text("Name")
                        .padding([.top, .bottom], 5)
                    TextField("Item Name", text: Bindable(eventExpenseViewModel).items.first(where: {$0.id == item.id})!.itemName)
                        .padding(10)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                } // Title
                VStack(alignment: .leading){
                    Text("Price")
                        .padding([.top, .bottom], 5)
                    HStack{
                        Text("Rp")
                        TextField("10.000", value: Bindable(eventExpenseViewModel).items.first(where: {$0.id == item.id})!.itemPrice, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
//                            .onReceive(Just(price)) { _ in
//                                price = price.formatPrice()
//                                item.itemPrice = Float(price.removeDots()) ?? 0
//                                eventExpenseViewModel.calculateTotal()
//                            }
                            .padding(10)
                            .background(Color(.midLightGray))
                            .cornerRadius(5)
                    }
                    VStack(alignment: .leading){
                        Text("Quantity")
                            .padding([.top, .bottom], 5)
                        HStack{
                            Text("-")
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(eventExpenseViewModel.items[index].itemQuantity != 1 ? Color(.lightGray) : Color(.midLightGray))
                                )
                                .onTapGesture {
                                    eventExpenseViewModel.items[index].itemQuantity-=1
                                }
                                .disabled(eventExpenseViewModel.items[index].itemQuantity == 1 ? true : false)
                            Text(String(eventExpenseViewModel.items[index].itemQuantity.formatted(.number)))
                                .padding([.leading, .trailing], 10)
                            Text("+")
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.lightGray))
                                )
                                .onTapGesture {
                                    eventExpenseViewModel.items[index].itemQuantity+=1
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
