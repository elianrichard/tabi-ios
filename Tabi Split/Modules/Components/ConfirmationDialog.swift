//
//  ConfirmationDialog.swift
//  Tabi Split
//

import SwiftUI
import Lottie

struct ConfirmationDialog: View {
    let animationName: String
    let animationScale: CGFloat
    let animationSaturation: CGFloat
    let title: String
    let message: String
    let confirmLabel: String
    let confirmColor: Color
    let onCancel: () -> Void
    let onConfirm: () async -> Void

    init(
        animationName: String,
        animationScale: CGFloat = 1.0,
        animationSaturation: CGFloat = 1.0,
        title: String,
        message: String,
        confirmLabel: String = "Confirm",
        confirmColor: Color = .buttonBlue,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () async -> Void
    ) {
        self.animationName = animationName
        self.animationScale = animationScale
        self.animationSaturation = animationSaturation
        self.title = title
        self.message = message
        self.confirmLabel = confirmLabel
        self.confirmColor = confirmColor
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(spacing: 0) {
                LottieView(animation: .named(animationName))
                    .looping()
                    .resizable()
                    .scaleEffect(animationScale)
                    .frame(width: 200, height: 200)
                    .saturation(animationSaturation)
                    .scaledToFit()
                VStack(spacing: .spacingSmall) {
                    Text(title)
                        .font(.tabiSubtitle)
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.tabiBody)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxHeight: .infinity)
            HStack {
                CustomButton(text: "Cancel", type: .secondary, action: onCancel)
                CustomButton(text: confirmLabel, customBackgroundColor: confirmColor) {
                    Task { await onConfirm() }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
