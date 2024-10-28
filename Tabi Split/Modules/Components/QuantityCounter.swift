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
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(quantity != (letZero ? 0 : 1) ? .buttonBlue : .buttonGrey)
                )
                .onTapGesture {
                    quantity -= 1
                }
                .disabled(quantity == (letZero ? 0 : 1) ? true : false)
            Text(String(quantity.formatted(.number)))
                .padding([.leading, .trailing], 10)
            Text("+")
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(.buttonBlue)
                )
                .onTapGesture {
                    quantity += 1
                }
        }
        .padding(10)
    }
}
