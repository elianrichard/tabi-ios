//
//  PriceInput.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 25/10/24.
//

import Foundation
import SwiftUI

struct PriceInput: View {
    var placeholder: String = ""
    @State var placeholderPrice: String = ""
    @Binding var price: Float
    var type: UIKeyboardType = .numberPad
    var isError: Bool = false
    var backgroundColor: Color = .bgWhite
    var cornerRadius: CGFloat = .radiusMedium
    var isDisabled: Bool = false
    
    var body: some View {
        HStack{
            Text("Rp")
            TextField(placeholder, text: $placeholderPrice)
                .frame(height: 20)
                .keyboardType(type)
                .onChange(of: placeholderPrice) {
                    placeholderPrice = placeholderPrice.formatPrice()
                    price = Float(placeholderPrice.removeDots()) ?? 0
                }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(isDisabled ? .uiGray : backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .foregroundStyle(isDisabled ? .textGrey : .black)
        .font(.tabiBody)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.clear)
                .stroke(isError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                .padding(0.5)
        }
        .onAppear{
            placeholderPrice = price != 0 ? price.formatPrice() : ""
        }
    }
}
