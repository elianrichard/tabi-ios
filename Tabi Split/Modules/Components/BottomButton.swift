//
//  BottomButton.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct BottomButton: View {
    var text: String = "Next"
    var color: Color = Color(.buttonBlue)
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .center){
            Text(text)
                .font(.headline)
                .foregroundColor(.bgWhite)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(color)
        .cornerRadius(20)
    }
}
