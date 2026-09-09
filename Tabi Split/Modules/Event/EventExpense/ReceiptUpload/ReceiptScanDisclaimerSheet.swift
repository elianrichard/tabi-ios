//
//  ReceiptScanDisclaimerSheet.swift
//  Tabi Split
//
//  Shown before the user opens the library or camera to scan a receipt. Sets
//  expectations about the OCR/AI and how to take a good photo. The user can opt
//  out with "Do not show again" (reset on login). Continue proceeds to the picker.
//

import SwiftUI

struct ReceiptScanDisclaimerSheet: View {
    @Binding var isPresented: Bool
    /// Called after the user confirms — proceeds to the library/camera.
    let onContinue: () -> Void

    private let tips: [String] = [
        "Our scanner reads the receipt automatically and may make mistakes, so review the items afterwards.",
        "Unfold the receipt and lay it flat and straight.",
        "Make sure the text is sharp, well-lit, and not wet or faded.",
        "Keep your fingers off the text, and fit the whole receipt in the frame from top to bottom, not cropped.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetXButton(toggle: $isPresented)

            VStack(spacing: .spacingMedium) {
                Image(.dialogIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .padding(.spacingRegular)
                    .background {
                        RoundedRectangle(cornerRadius: .radiusLarge)
                            .fill(.bgBlueElevated)
                    }

                Text("Before you scan")
                    .font(.tabiSubtitle)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: .spacingSmall) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: .spacingSmall) {
                            Icon(systemName: "checkmark.circle.fill", color: .buttonBlue, size: 16)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.tabiBody)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            // Primary CTA + a ghost action that also opts out of the disclaimer.
            VStack(spacing: .spacingSmall) {
                CustomButton(text: "Continue") {
                    proceed(dismissForever: false)
                }
                CustomButton(text: "Continue and do not show this again", type: .tertiary, customTextColor: .buttonRed) {
                    proceed(dismissForever: true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .padding([.top], 10)
        .addBackgroundColor(.bgWhite)
    }

    private func proceed(dismissForever: Bool) {
        if dismissForever {
            UserDefaultsService.shared.setReceiptScanDisclaimerDismissed(true)
        }
        isPresented = false
        onContinue()
    }
}

#Preview {
    ReceiptScanDisclaimerSheet(isPresented: .constant(true), onContinue: {})
}
