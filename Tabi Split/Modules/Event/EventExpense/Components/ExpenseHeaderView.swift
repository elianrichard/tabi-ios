//
//  ExpenseHeaderView.swift
//  Tabi Split
//
//  Shared header for the expense item/assign screens: the expense name, a split-
//  method Nugget, and a "See Receipt" Nugget button that opens the attached
//  receipt (the local image in the create flow, or the stored image id on edit).
//

import SwiftUI

struct ExpenseHeaderView: View {
    /// When false, only the nuggets are shown (no expense-name title) — used on the
    /// assign screen where the title would be redundant.
    var showTitle: Bool = true

    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @State private var isShowReceipt = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingTight) {
            if showTitle {
                Text(eventExpenseViewModel.expenseName)
                    .font(.tabiTitle)
                    .lineLimit(1)
            }
            HStack(spacing: .spacingSmall) {
                if let method = eventExpenseViewModel.selectedMethod {
                    Nugget(text: method.splitDescription, icon: .resource(method.icon), color: .yellow)
                }
                // Peek at the attached receipt: the just-scanned local image in the
                // create flow, or the stored image (by id) when editing.
                if eventExpenseViewModel.hasReceipt {
                    Button {
                        isShowReceipt = true
                    } label: {
                        Nugget(text: "See Receipt", icon: .system("doc.text.image"), color: .blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.bottom], showTitle ? 24 : 16)
        .fullScreenCover(isPresented: $isShowReceipt) {
            if let image = eventExpenseViewModel.uploadedReceiptImage {
                ReceiptViewerView(image: image, isPresented: $isShowReceipt)
            } else if let id = eventExpenseViewModel.uploadedReceiptId, !id.isEmpty {
                ReceiptViewerView(receiptId: id, isPresented: $isShowReceipt)
            }
        }
    }
}
