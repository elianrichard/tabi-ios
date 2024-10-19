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
    @Bindable var item: AdditionalCharge
    @State var price: String = ""
    
    var body: some View {
        HStack {
            Menu {
                ForEach(AdditionalChargeType.allCases) { type in
                    Button(type.name, action: {
                        eventExpenseViewModel.additionalCharges.first(where: {$0.id == item.id})?.additionalChargeType = type.id
                    })
                    .frame(maxWidth: .infinity)
                }
            } label: {
                HStack{
                    Text(AdditionalChargeType(rawValue: eventExpenseViewModel.additionalCharges.first(where: {$0.id == item.id})!.additionalChargeType)?.name ?? "unknown")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .foregroundColor(.black)
                .background(Color(.midLightGray))
                .cornerRadius(5)
            }
            HStack{
                Text("Rp")
                TextField("10.000", value: Bindable(eventExpenseViewModel).additionalCharges.first(where: {$0.id == item.id})!.amount, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
//                    .onReceive(Just(price)) { _ in
//                        price = price.formatPrice()
//                        item.amount = Float(price.removeDots()) ?? 0
//                        eventExpenseViewModel.calculateTotal()
//                    }
            }
            .padding(10)
            .background(Color(.midLightGray))
            .cornerRadius(5)
        }
    }
}
