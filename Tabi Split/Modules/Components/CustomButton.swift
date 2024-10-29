//
//  Button.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

enum ButtonType {
    case primary, secondary
    
    func backgroundColor (_ isEnabled: Bool = true) -> Color {
        switch self {
        case .primary:
            if (isEnabled) {
                return .buttonBlue
            } else {
                return .bgGreyOverlay
            }
        case .secondary:
            return .buttonWhite
        }
    }
    
    func textColor (_ isEnabled: Bool = true) -> Color {
        switch self {
        case .primary:
            return .textWhite
        case .secondary:
            if (isEnabled) {
                return .textBlue
            } else {
                return .textGrey
            }
        }
    }
}

struct CustomButton: View {
    var text: String
    var type: ButtonType = .primary
    var isEnabled: Bool = true
    var icon: String?
    var iconResource: ImageResource?
    var iconSize: CGFloat = 20
    var customBackgroundColor: Color?
    var customTextColor: Color?
    var vPadding: CGFloat?
    var hPadding: CGFloat?
    var callback: () -> Void
    
    var body : some View {
        Button {
            if (isEnabled) {
                callback()
            }
        } label: {
            HStack (spacing: 8) {
                if let icon = icon {
                    Icon(systemName: icon, color: .textWhite, size: iconSize)
                } else if let resource = iconResource {
                    Icon(resource, color: .textWhite, size: iconSize)
                }
                Text("\(text)")
                    .foregroundStyle(customTextColor != nil ? customTextColor ?? .primary : type.textColor(isEnabled))
            }
            .padding(.vertical, vPadding ?? UIConfig.Spacing.Tight)
            .padding(.horizontal, hPadding)
            .frame(maxWidth: hPadding != nil ? nil : .infinity)
            .background(customBackgroundColor != nil ? customBackgroundColor : type.backgroundColor(isEnabled))
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
            .font(.tabiHeadline)
            .overlay {
                if type == .secondary {
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.clear)
                        .stroke(isEnabled ? .buttonBlue : .bgGreyOverlay, lineWidth: 1.5)
                }
            }
            .padding(type == .secondary ? 1 : 0)
        }
    }
}

#Preview {
    CustomButton(text: "Primary", type: .primary, isEnabled: true) {
        print("Hello Primary!")
    }
    CustomButton(text: "Secondary", type: .secondary, isEnabled: true) {
        print("Hello Secondary!")
    }
    CustomButton(text: "Primary", type: .primary, isEnabled: false) {
        print("Hello Primary!")
    }
    CustomButton(text: "Secondary", type: .secondary, isEnabled: false) {
        print("Hello Secondary!")
    }
}
