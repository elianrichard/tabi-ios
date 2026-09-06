//
//  InviteShareButtons.swift
//  Tabi Split
//
//  Created by Claude on 06/09/26.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

/// The Copy Link / Share Link / QR Code row shared by the event-invite and
/// participant-claim flows. It is driven entirely by a resolved invite URL: while
/// `urlString` is nil (token still loading) the buttons are inert. The component
/// owns its own transient "Copied!" state and QR sheet so callers only supply the
/// URL and the accompanying share copy.
struct InviteShareButtons: View {
    /// Full invite URL (https://.../join?token=...). Nil until a token resolves.
    let urlString: String?
    /// Plain-text blurb + URL, pasted by Copy Link (URL must be inline here).
    let copyMessage: String?
    /// Friendly blurb WITHOUT the URL, used as the Share sheet's message —
    /// ShareLink adds the URL via `item:`, so including it here shows it twice.
    let shareIntro: String
    /// Called when the owner uses any share action (Copy / Share / QR). Lets a
    /// caller start watching for someone opening the shared link. Optional.
    var onShareAction: (() -> Void)? = nil

    @State private var isLinkCopied = false
    @State private var isShowQrSheet = false

    var body: some View {
        HStack(spacing: .spacingMedium) {
            EventInviteShareButtonView(text: isLinkCopied ? "Copied!" : "Copy Link",
                                       icon: isLinkCopied ? .checkIcon : .linkIcon,
                                       action: {
                guard let message = copyMessage, !isLinkCopied else { return }
                withAnimation(nil) { isLinkCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(nil) { isLinkCopied = false }
                }
                UIPasteboard.general.setValue(message, forPasteboardType: UTType.plainText.identifier)
                onShareAction?()
            })
            if let urlString, let url = URL(string: urlString) {
                ShareLink(item: url, message: Text(shareIntro)) {
                    EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
                }
                .simultaneousGesture(TapGesture().onEnded { onShareAction?() })
            } else {
                EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
            }
            EventInviteShareButtonView(text: "QR Code",
                                       icon: .qrIcon,
                                       action: {
                isShowQrSheet = true
                onShareAction?()
            })
        }
        .sheet(isPresented: $isShowQrSheet) {
            CustomSheet(xToggleBinding: $isShowQrSheet) {
                VStack(alignment: .center, spacing: .spacingSmall) {
                    Text("Show QR Code")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .center, spacing: .spacingMedium) {
                        Image(uiImage: generateQRCode(from: urlString ?? ""))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        Text("Let your friends scan it to participate in your event")
                            .font(.tabiHeadline)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.bgWhite)
        }
    }

    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 1, y: 1)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(outputImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
