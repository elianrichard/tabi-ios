//
//  AddItemContainer.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct AddItemContainer: View {
    @State var itemNum: Int
    @Binding var item: Item
    @Binding var viewModel: ExpenseEqualSplitViewModel
    
    var body: some View {
        VStack{
            VStack(alignment: .leading){
                HStack{
                    Text("Item " + String(itemNum))
                    Spacer()
                    Image(systemName: "trash")
                        .onTapGesture {
                            viewModel.deleteItem(item: item)
                        }
                }
                Divider()
                VStack(alignment: .leading){
                    Text("Name")
                        .padding([.top, .bottom], 5)
                    TextField("Item Name", text: $item.itemName)
                        .padding(10)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                } // Title
                VStack(alignment: .leading){
                    Text("Price")
                        .padding([.top, .bottom], 5)
                    HStack{
                        Text("Rp")
                        TextField("0", value: $item.itemPrice, format: .number .grouping(.automatic)
                        )
                        .keyboardType(.numberPad)
                    }
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
                                    .fill(item.itemQuantity != 1 ? Color(.lightGray) : Color(.midLightGray))
                            )
                            .onTapGesture {
                                item.itemQuantity-=1
                            }
                            .disabled(item.itemQuantity == 1 ? true : false)
                        Text(String(item.itemQuantity))
                            .padding([.leading, .trailing], 10)
                        Text("+")
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color(.lightGray))
                            )
                            .onTapGesture {
                                item.itemQuantity+=1
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
        .padding([.top, .bottom], 5)
    }
}
