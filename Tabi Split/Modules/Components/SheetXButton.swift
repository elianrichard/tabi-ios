//
//  SheetXButton.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 04/11/24.
//

import Foundation
import SwiftUI

struct SheetXButton: View {
    @Binding var toggle: Bool
    var body: some View {
        HStack{
            Button{
                toggle.toggle()
            }label: {
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.uiGray)
                    .overlay {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.textGrey)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
