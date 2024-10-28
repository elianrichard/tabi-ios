//
//  TopNavigation.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct TopNavigation<Content: View>: View {
    @Environment(Routes.self) var routes
    
    var RightToolbar: Content
    var title: String
    var isCircleBackButton: Bool
    var additionalBackFunction: (() -> Void)?
    
    init(title: String, isCircleBackButton: Bool = false,  @ViewBuilder RightToolbar: () -> Content, additionalBackFunction: (() -> Void)? = nil) {
        self.RightToolbar = RightToolbar()
        self.title = title
        self.isCircleBackButton = isCircleBackButton
        self.additionalBackFunction = additionalBackFunction
    }
    
    var body: some View {
        VStack {
            ZStack {
                Text(title)
                    .font(.tabiSubtitle)
                    .foregroundStyle(.textWhite)
                HStack {
                    Button {
                        if let backFunction = additionalBackFunction {
                            backFunction()
                        }
                        routes.navigateBack()
                    } label: {
                        Icon(systemName: "arrow.left", size: 14)
                            .frame(width: 28, height: 28)
                            .background(isCircleBackButton ? .white : .clear)
                            .cornerRadius(.infinity)
                    }
                    Spacer()
                    RightToolbar
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            Spacer()
        }
        .zIndex(100)
    }
}

#Preview {
    TopNavigation (title: "Testing") {
        Text("Hello")
    } additionalBackFunction: {
        print("Holaaa")
    }
    .environment(Routes())
}
