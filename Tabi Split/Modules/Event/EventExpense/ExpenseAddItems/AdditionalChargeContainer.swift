//
//  AdditionalChargeContainer.swift
//  Tabi Split
//
//  Created by Elian Richard on 14/10/24.
//

import SwiftUI
import Combine

struct AdditionalChargeContainer: View {
    @Environment(EventExpenseViewModel.self) var eventExpenseViewModel
    @Binding var item: AdditionalCharge
    @State var price: String = ""
    
    var body: some View {
        HStack {
            Menu {
                ForEach(AdditionalChargeType.allCases) { type in
                    Button(type.name, action: {
                        item.additionalChargeType = type.id
                    })
                    .frame(maxWidth: .infinity)
                }
            } label: {
                HStack{
                    Text(AdditionalChargeType(rawValue: item.additionalChargeType)?.name ?? "unknown")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .foregroundColor(.black)
                .background(.uiGray)
                .cornerRadius(5)
            }
            HStack{
                Text("Rp")
                TextField("10.000", text: $price)
                    .keyboardType(.numberPad)
                    .onChange(of: price) {
                        price = price.formatPrice()
                        item.amount = Float(price.removeDots()) ?? 0
                        eventExpenseViewModel.calculateTotal()
                    }
            }
            .onAppear(){
                price = item.amount != 0 ? String(item.amount.formatted()) : ""
            }
            .onChange(of: item.amount){
                price = item.amount != 0 ? String(item.amount.formatted()) : ""
            }
            .padding(10)
            .background(.uiGray)
            .cornerRadius(5)
            
            Image(systemName: "trash")
                .onTapGesture {
                    eventExpenseViewModel.deleteAdditionalCharge(item: item)
                    eventExpenseViewModel.calculateTotal()
                }
        }
    }
}
