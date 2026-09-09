//
//  QuickScanEventPickerView.swift
//  Tabi Split
//
//  Reached when a receipt image is shared into the app (Share Extension →
//  tabisplit://quickscan). The user picks which event the receipt belongs to;
//  the shared image is then attached and the manual add-expense flow opens with
//  the image already in the receipt field.
//

import SwiftUI

struct QuickScanEventPickerView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel

    @State private var events: [EventData] = []

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingRegular) {
            TopNavigation(title: "Add to Event")

            HStack(spacing: .spacingXSmall) {
                Icon(systemName: "info.circle.fill", color: .buttonBlue, size: 14)
                Text("Choose an event for this receipt")
                    .font(.tabiBody2)
                    .foregroundStyle(.buttonBlue)
            }

            if events.isEmpty {
                VStack(spacing: .spacingSmall) {
                    Text("No events yet")
                        .font(.tabiHeadline)
                    Text("Create an event first, then share a receipt to add an expense.")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .spacingTight) {
                        ForEach(events) { event in
                            Button {
                                selectEvent(event)
                            } label: {
                                EventCard(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            events = (SwiftDataService.shared.fetchAllEvents() ?? [])
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func selectEvent(_ event: EventData) {
        eventViewModel.selectedEvent = event
        eventExpenseViewModel.resetViewModel()
        eventExpenseViewModel.isQuickScanned = false
        // Stash the shared image as PENDING (not uploadedReceiptImage) so it doesn't
        // trigger the receipt-review push observers mid-navigation. AddExpenseView
        // attaches it on appear.
        let sharedImage = AppGroup.loadSharedReceipt()
        print("[QuickScanPicker] loadSharedReceipt → \(sharedImage.map { "\(Int($0.size.width))x\(Int($0.size.height))" } ?? "nil")")
        eventExpenseViewModel.pendingSharedReceiptImage = sharedImage
        AppGroup.clearSharedReceipt()

        router.popToRoot()
        router.push(.eventDetail)
        router.push(.addExpense)
    }
}

#Preview {
    QuickScanEventPickerView()
        .environment(Router())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
