//
//  BottomButton.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct BottomButton: View {
    @State var text: String
    
    var body: some View {
        VStack(alignment: .center){
            Text(text)
                .foregroundColor(.black)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(.lightGray))
        .cornerRadius(20)
        .padding([.leading, .trailing], 30)
        .padding([.top, .bottom], 10)
    }
}
