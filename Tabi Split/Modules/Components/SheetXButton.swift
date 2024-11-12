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
            Button {
                toggle = false
            } label : {
                Icon(systemName: "xmark", color: .textGrey, size: 12)
                    .frame(width: 32, height: 32)
                    .background(.uiGray)
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
