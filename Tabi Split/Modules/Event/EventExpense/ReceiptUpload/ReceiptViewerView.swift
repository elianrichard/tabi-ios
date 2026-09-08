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
    /// Where the receipt image comes from: a stored image id (fetched via
    /// GET /image/:id) for a saved expense, or a local UIImage for the create flow
    /// where the image is attached but not yet uploaded.
    enum Source {
        case remote(id: String)
        case local(UIImage)
    }

    let source: Source
    @Binding var isPresented: Bool

    // Convenience inits so call sites read naturally.
    init(receiptId: String, isPresented: Binding<Bool>) {
        self.source = .remote(id: receiptId)
        self._isPresented = isPresented
    }
    init(image: UIImage, isPresented: Binding<Bool>) {
        self.source = .local(image)
        self._isPresented = isPresented
    }

    @State private var receiptURL: URL?
    @State private var localImage: UIImage?
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

            if let localImage {
                // Create flow: the attached-but-not-yet-uploaded image.
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnification)
                    .simultaneousGesture(dragToPan)
                    .onTapGesture(count: 2) { resetZoom() }
            } else if isLoading {
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
        switch source {
        case .local(let image):
            localImage = image
        case .remote(let id):
            if receiptURL != nil { return }
            isLoading = true
            loadError = false
            defer { isLoading = false }
            do {
                let detail = try await ImageService.shared.imageDetail(id: id)
                receiptURL = URL(string: detail.full_path)
            } catch {
                loadError = true
            }
        }
    }
}
