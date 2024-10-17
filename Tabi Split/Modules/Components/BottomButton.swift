//
//  BottomButton.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct BottomButton: View {
    @State var text: String = "Next"
    @State var color: Color = Color(.buttonBlue)
    
    var body: some View {
        VStack(alignment: .center){
            Text(text)
                .foregroundColor(.white)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(color)
        .cornerRadius(20)
    }
}
