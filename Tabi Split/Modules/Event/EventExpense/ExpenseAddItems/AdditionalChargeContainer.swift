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
        GeometryReader { geometry in
            HStack {
                HStack{
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
                        .frame(maxWidth: .infinity)
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
                        .accentColor(.textBlack)
                    }
                    .onChange(of: item.additionalChargeType) {
                        price = price.formatPrice(isShowSign: false)
                        if (item.additionalChargeType == AdditionalChargeType.discount.id) {
                            item.amount = abs(Float(price.removeDots()) ?? 0) * -1
                        } else {
                            item.amount = abs(Float(price.removeDots()) ?? 0)
                        }
                        eventExpenseViewModel.calculateTotal()
                    }
                }
                .frame(width: geometry.size.width * 0.4)
                HStack{
                    TextField("Enter amount", text: $price)
                        .keyboardType(.numberPad)
                        .onChange(of: price) {
                            price = price.formatPrice(isShowSign: false)
                            if (item.additionalChargeType == AdditionalChargeType.discount.id) {
                                item.amount = abs(Float(price.removeDots()) ?? 0) * -1
                            } else {
                                item.amount = abs(Float(price.removeDots()) ?? 0)
                            }
                            eventExpenseViewModel.calculateTotal()
                        }
                        .font(.tabiBody)
                }
                .onAppear(){
                    price = item.amount != 0 ? String(item.amount.formatted()) : ""
                }
                .onChange(of: item.amount){
                    price = item.amount != 0 ? String(item.amount.formatted()) : ""
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
                
                Button{
                    eventExpenseViewModel.deleteAdditionalCharge(item: item)
                    eventExpenseViewModel.calculateTotal()
                }label:{
                    Icon(systemName: "trash", color: .buttonRed, size: 18)
                }
            }
        }
        .frame(height: 50)
    }
}
