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
        VStack(alignment: .leading, spacing: 16){
            HStack{
                Text("Item " + String(index + 1))
                Spacer()
                Button{
                    eventExpenseViewModel.deleteItem(item: item)
                    eventExpenseViewModel.calculateTotal()
                }label:{
                    Icon(systemName: "trash", color: .buttonRed, size: 18)
                }
            }
            .font(.tabiBody)
            HStack(){
                Text("Name")
                    .foregroundColor(.textGrey)
                    .frame(width: 45)
                TextField("Enter item name", text: Bindable(item).itemName)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.bgWhite)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .stroke(.bgGreyOverlay, lineWidth: 0.5)
                            .padding(0.5)
                    }
            }
            .font(.tabiBody)
            HStack(spacing: 8){
                HStack{
                    Text("Price")
                        .foregroundColor(.textGrey)
                        .frame(width: 45)
                    TextField("Enter item Price", text: $price)
                        .keyboardType(.numberPad)
                        .onChange(of: price) {
                            price = price.formatPrice()
                            item.itemPrice = Float(price.removeDots()) ?? 0
                            eventExpenseViewModel.calculateTotal()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.bgWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.clear)
                                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                        .frame(width: 110)
                }
                .onReceive(Just(item.itemPrice)) { _ in
                    price = item.itemPrice != 0 ? String(item.itemPrice.formatPrice()) : ""
                }
                Spacer()
                HStack{
                    Text("Qty")
                        .foregroundColor(.textGrey)
                    HStack{
                        QuantityCounter(quantity: Bindable(item).itemQuantity)
                            .onChange(of: item.itemQuantity){
                                eventExpenseViewModel.calculateTotal()
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.tabiBody)
        }
        .padding()
        .background(.bgWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                .padding(0.5)
        }
    }
}

#Preview {
    AddItemContainer(item: .constant(ExpenseItem(itemName: "Test", itemPrice: 20000, itemQuantity: 1)), price: "30000", index: 0)
        .environment(EventExpenseViewModel())
}
