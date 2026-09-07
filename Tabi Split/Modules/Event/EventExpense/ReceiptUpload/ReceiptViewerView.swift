//
//  ReceiptViewerView.swift
//  Tabi Split
//
//  Full-screen modal receipt viewer with pinch-to-zoom and pan. Loads a fresh
//  signed URL for a stored image id (GET /image/:id) and renders it zoomable.
//  Native gestures only — no third-party dependency.
//

import SwiftUI

struct ReceiptViewerView: View {
    /// Backend image id of the receipt to display.
    let receiptId: String
    @Binding var isPresented: Bool

    @State private var receiptURL: URL?
    @State private var isLoading = false
    @State private var loadError = false

    // Committed zoom/offset (persist between gestures) + live gesture deltas.
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let receiptURL {
                AsyncImage(url: receiptURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(magnification)
                            .simultaneousGesture(dragToPan)
                            .onTapGesture(count: 2) { resetZoom() }
                    case .failure:
                        errorLabel
                    case .empty:
                        ProgressView().tint(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if loadError {
                errorLabel
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Icon(systemName: "xmark", color: .textWhite, size: 14)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding()
        }
        .task { await loadReceipt() }
    }

    private var errorLabel: some View {
        Text("Could not load receipt")
            .font(.tabiBody)
            .foregroundStyle(.textWhite)
    }

    // Pinch: multiply the committed scale by the live gesture value, clamped.
    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= minScale { resetPan() }
            }
    }

    // Pan only makes sense while zoomed in.
    private var dragToPan: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > minScale else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func resetZoom() {
        withAnimation(.spring(response: 0.3)) {
            scale = 1
            lastScale = 1
            resetPan()
        }
    }

    private func resetPan() {
        offset = .zero
        lastOffset = .zero
    }

    @MainActor
    private func loadReceipt() async {
        if receiptURL != nil { return }
        isLoading = true
        loadError = false
        defer { isLoading = false }
        do {
            let detail = try await ImageService.shared.imageDetail(id: receiptId)
            receiptURL = URL(string: detail.full_path)
        } catch {
            loadError = true
        }
    }
}

#Preview {
    ReceiptViewerView(receiptId: "preview", isPresented: .constant(true))
}
