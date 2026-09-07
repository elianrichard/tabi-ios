//
//  NuggetView.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

/// A pill/tag. Two flavours:
/// - Selectable filter (the original `init(text:isSelected:)`): blue when selected,
///   grey outline otherwise.
/// - Coloured tag (`init(text:icon:color:)`): a soft tinted capsule with a matching
///   accent for the icon/text/border — e.g. a green "paid" tag or a yellow split tag.
struct Nugget: View {
    var text: String
    var icon: NuggetIcon?
    private var style: NuggetStyle

    /// Original selectable filter pill. Kept for existing call sites.
    init(text: String, isSelected: Bool) {
        self.text = text
        self.icon = nil
        self.style = .filter(isSelected: isSelected)
    }

    /// Coloured tag with an optional leading icon.
    init(text: String, icon: NuggetIcon? = nil, color: NuggetColor) {
        self.text = text
        self.icon = icon
        self.style = .tag(color)
    }

    var body: some View {
        HStack(spacing: .spacingXSmall) {
            if let icon {
                switch icon {
                case .resource(let resource):
                    Icon(resource, color: style.foreground, size: 16)
                case .system(let name):
                    Icon(systemName: name, color: style.foreground, size: 14)
                }
            }
            Text(text)
                .font(style.font)
                .foregroundStyle(style.foreground)
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, .spacingSmall)
        .background(style.background)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(style.border, lineWidth: 1)
        }
    }
}

/// The leading icon for a coloured Nugget — an asset or an SF Symbol.
enum NuggetIcon {
    case resource(ImageResource)
    case system(String)
}

/// The colour theme of a tag Nugget. Each maps to a soft highlight background
/// with a matching solid accent for the icon/text/border.
enum NuggetColor {
    case green, yellow, red, blue

    var background: Color {
        switch self {
        case .green: return .highlightGreen
        case .yellow: return .highlightYellow
        case .red: return .highlightRed
        case .blue: return .buttonBlueSelected
        }
    }

    var accent: Color {
        switch self {
        case .green: return .buttonGreen
        case .yellow: return .buttonYellow
        case .red: return .buttonRed
        case .blue: return .buttonBlue
        }
    }
}

private enum NuggetStyle {
    case filter(isSelected: Bool)
    case tag(NuggetColor)

    var background: Color {
        switch self {
        case .filter(let isSelected): return isSelected ? .buttonBlueSelected : .clear
        case .tag(let color): return color.background
        }
    }

    var foreground: Color {
        switch self {
        case .filter: return .black
        case .tag(let color): return color.accent
        }
    }

    var border: Color {
        switch self {
        case .filter(let isSelected): return isSelected ? .buttonBlue : .uiGray
        case .tag(let color): return color.accent.opacity(0.35)
        }
    }

    var font: Font {
        switch self {
        case .filter: return .tabiBody
        case .tag: return .tabiBody2
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .filter: return 24
        case .tag: return .spacingTight
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        Nugget(text: "All", isSelected: true)
        Nugget(text: "All", isSelected: false)
        Nugget(text: "Daniel paid", icon: .system("person.fill"), color: .green)
        Nugget(text: "Split custom", icon: .system("slider.horizontal.3"), color: .yellow)
    }
    .padding()
}
