//
//  Button.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/10/24.
//

import SwiftUI

enum ButtonType {
    case primary, secondary, tertiary
    
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
        case .tertiary:
            return .clear
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
        case .tertiary:
            return .textBlue
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
            callback()
        } label: {
            HStack (spacing: 8) {
                if let icon = icon {
                    Icon(systemName: icon, color: type.textColor(isEnabled), size: iconSize)
                } else if let resource = iconResource {
                    Icon(resource, color: type.textColor(isEnabled), size: iconSize)
                }
                Text("\(text)")
                    .foregroundStyle(customTextColor != nil ? customTextColor ?? .primary : type.textColor(isEnabled))
            }
            .padding(.vertical, vPadding ?? .spacingRegular)
            .padding(.horizontal, hPadding)
            .frame(maxWidth: hPadding != nil || type == .tertiary ? nil : .infinity)
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
            .transaction { transaction in 
                transaction.animation = nil
            }
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    CustomButton(text: "Primary", type: .primary, isEnabled: true, icon: "flag") {
        print("Hello Primary!")
    }
    CustomButton(text: "Secondary", type: .secondary, isEnabled: true, icon: "flag") {
        print("Hello Secondary!")
    }
    CustomButton(text: "Primary", type: .primary, isEnabled: false, icon: "flag") {
        print("Hello Primary!")
    }
    CustomButton(text: "Secondary", type: .secondary, isEnabled: false, icon: "flag") {
        print("Hello Secondary!")
    }
    CustomButton(text: "Tertiary", type: .tertiary, isEnabled: true, icon: "flag") {
        print("Hello Tertiary!")
    }
}
