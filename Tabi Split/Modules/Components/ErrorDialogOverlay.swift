//
//  ErrorDialogOverlay.swift
//  Tabi Split
//
//  Created by Elian Richard on 31/08/26.
//

import SwiftUI

// Global blocking error dialog: a dimmed backdrop over the whole app with a
// centered card and an OK button. Mounted once at the app root (ContentView) and
// driven by ErrorDialogViewModel.shared, so any API error surfaces here.
struct ErrorDialogOverlay: View {
    private var errorDialogViewModel = ErrorDialogViewModel.shared

    var body: some View {
        ZStack {
            if let message = errorDialogViewModel.message {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        errorDialogViewModel.dismiss()
                    }

                VStack(spacing: .spacingMedium) {
                    VStack(spacing: .spacingSmall) {
                        Icon(systemName: "exclamationmark.triangle.fill", color: .buttonRed, size: 40)
                        Text("Something went wrong")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text(message)
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    CustomButton(text: "OK") {
                        errorDialogViewModel.dismiss()
                    }
                }
                .padding(.spacingLarge)
                .frame(maxWidth: .infinity)
                .background(.bgWhite)
                .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                .padding(.horizontal, .spacingLarge)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: errorDialogViewModel.message)
    }
}

#Preview {
    ErrorDialogOverlay()
}
