//  TopNavigation.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct TopNavigation<Content: View>: View {
    @Environment(Routes.self) var routes
    
    var RightToolbar: Content?
    var title: String
    var titleColor: Color
    var isCircleBackButton: Bool
    var isInline: Bool
    var additionalBackFunction: (() -> Void)?
    
    init(title: String, titleColor: Color = .textBlack, isCircleBackButton: Bool = false, isInline: Bool = true, @ViewBuilder RightToolbar: () -> Content = { EmptyView() }, additionalBackFunction: (() -> Void)? = nil) {
        self.RightToolbar = RightToolbar()
        self.title = title
        self.titleColor = titleColor
        self.isCircleBackButton = isCircleBackButton
        self.isInline = isInline
        self.additionalBackFunction = additionalBackFunction
    }
    
    var body: some View {
        VStack {
            ZStack {
                Text(title)
                    .font(.tabiSubtitle)
                    .foregroundStyle(titleColor)
                HStack {
                    Button {
                        if let backFunction = additionalBackFunction {
                            backFunction()
                        }
                        routes.navigateBack()
                    } label: {
                        if isCircleBackButton {
                            Icon(systemName: "arrow.left", size: 16)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(.white)
                                )
                        } else {
                            Icon(systemName: "arrow.left", size: 16)
                        }
                    }
                    .padding(isCircleBackButton ? 8 : 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let backFunction = additionalBackFunction {
                            backFunction()
                        }
                        routes.navigateBack()
                    }
                    .padding(isCircleBackButton ? -8 : -16)
                    Spacer()
                    RightToolbar
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(isInline ? 0 : 20)
            if (!isInline) {
                Spacer()
            }
        }
        .padding(.bottom, 36)
        .zIndex(isInline ? 0 :  100)
    }
}

#Preview {
    ZStack {
        Color(.red)
        TopNavigation(title: "Testing", isCircleBackButton: true, isInline: true)
            .environment(Routes())
    }
}
