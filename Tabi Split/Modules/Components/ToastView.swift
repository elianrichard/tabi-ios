//
//  ToastView.swift
//  Tabi Split
//
//  Created by Elian Richard on 24/08/26.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let style: ToastStyle
    let onClose: () -> Void

    private var icon: String {
        switch style {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var accentColor: Color {
        switch style {
        case .error: return .buttonRed
        case .success: return .buttonGreen
        case .info: return .buttonBlue
        }
    }

    var body: some View {
        HStack(spacing: .spacingTight) {
            Icon(systemName: icon, color: accentColor, size: 20)
            Text(message)
                .font(.tabiBody)
                .foregroundStyle(.textBlack)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
            Spacer(minLength: 0)
            Button {
                onClose()
            } label: {
                Icon(systemName: "xmark", color: .textGrey, size: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingRegular)
        .padding(.horizontal, .spacingRegular)
        .background(.bgWhite)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMedium)
                .stroke(accentColor.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .padding(.horizontal, .spacingRegular)
    }
}

struct ToastOverlay: View {
    private var toastViewModel = ToastViewModel.shared

    var body: some View {
        VStack {
            if let message = toastViewModel.message {
                ToastView(message: message, style: toastViewModel.style) {
                    toastViewModel.dismiss()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, .spacingTight)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastViewModel.message)
    }
}

#Preview {
    ToastView(message: "Something went wrong. Please try again.", style: .error) {}
}
