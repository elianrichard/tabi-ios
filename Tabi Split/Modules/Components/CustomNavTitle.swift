//
//  CustomNavTitle.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 25/10/24.
//

import Foundation
import SwiftUI

struct CustomNavTitle: View {
    @Environment(Routes.self) private var routes
    var title: String = ""
    
    var body: some View {
        ZStack {
            Text(title)
                .font(.tabiSubtitle)
            HStack {
                Button {
                    routes.navigateBack()
                } label: {
                    Image(systemName: "arrow.left")
                        .foregroundStyle(.black)
                        .font(.tabiSubtitle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.bottom], 30)
    }
}
