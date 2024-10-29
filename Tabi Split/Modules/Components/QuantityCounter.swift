//
//  QuantityCounter.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 22/10/24.
//

import Foundation
import SwiftUI

struct QuantityCounter: View {
    @Binding var quantity: Float
    var letZero: Bool = false
    
    var body: some View {
        HStack{
            Text("-")
                .font(Font.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 29, height: 29)
                .background(
                    Circle()
                        .fill(quantity != (letZero ? 0 : 1) ? .buttonBlue : .buttonGrey)
                )
                .onTapGesture {
                    quantity -= 1
                }
                .disabled(quantity == (letZero ? 0 : 1) ? true : false)
            Text(quantity.formatted(.number))
                .frame(width: 40, alignment: .center)
                .foregroundColor(.black)
                .lineLimit(1)
            Text("+")
                .font(Font.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 29, height: 29)
                .background(
                    Circle()
                        .fill(.buttonBlue)
                )
                .onTapGesture {
                    quantity += 1
                }
        }
    }
}
