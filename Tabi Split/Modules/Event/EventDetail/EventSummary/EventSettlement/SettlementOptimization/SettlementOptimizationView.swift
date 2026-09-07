//
//  SettlementOptimizationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementOptimizationView: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel

    @State private var exportedPDF: ExportedPDF?
    /// Simplified: netted settlements (fewest transfers). Non-simplified: every
    /// direct debt between two people, no netting.
    @State private var isSimplified = true

    /// Recap rows for the active mode, current user's own row first.
    private var recapData: [PersonBalanceData] {
        let source = isSimplified ? eventViewModel.participantsBalance : eventViewModel.directSettlements
        let rows = source.filter { !$0.settlement.isEmpty }
        let current = rows.filter { profileViewModel.isCurrentUser($0.user) }
        let others = rows.filter { !profileViewModel.isCurrentUser($0.user) }
        return current + others
    }

    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Optimization Details", RightToolbar: {
                Button {
                    exportPDF()
                } label: {
                    Icon(systemName: "square.and.arrow.up", color: .textBlue, size: 18)
                }
                .padding(.trailing, 16)
            })
                .padding([.top, .horizontal])
            VStack (spacing: .spacingMedium) {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if let currentUserData = eventViewModel.participantsBalance.first(where: { profileViewModel.isCurrentUser($0.user) }){
                                OptimizationPersonCard(data: currentUserData)
                            }
                            ForEach (eventViewModel.participantsBalance.filter{ !profileViewModel.isCurrentUser($0.user) }) { data in
                                OptimizationPersonCard(data: data)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                VStack (alignment: .leading, spacing: .spacingRegular) {
                    HStack {
                        Text("Recapitulation")
                            .font(.tabiHeadline)
                        Spacer()
                        RecapModeToggle(isSimplified: $isSimplified)
                    }
                    ScrollView (showsIndicators: true) {
                        VStack (spacing: .spacingMedium) {
                            ForEach (recapData) { data in
                                OptimizationRecapCard(recapData: data)
                            }
                        }
                        .padding(.vertical, .spacingTight)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, .spacingRegular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radiusLarge)
                            .strokeBorder(.uiGray, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                    .padding(1)
                }
                .frame(maxHeight: .infinity)
                .padding([.bottom, .horizontal])
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $exportedPDF) { pdf in
            ShareSheet(items: [pdf.url])
        }
    }

    /// Participants ordered the same way the cards are: current user first.
    private var orderedParticipants: [PersonBalanceData] {
        let current = eventViewModel.participantsBalance.filter { profileViewModel.isCurrentUser($0.user) }
        let others = eventViewModel.participantsBalance.filter { !profileViewModel.isCurrentUser($0.user) }
        return current + others
    }

    /// Flattens a settlement source into PDF recap rows, current user's rows first
    /// (matching the on-screen ordering).
    private func recapPDF(from source: [PersonBalanceData]) -> [OptimizationRecapPDFData] {
        let rows = source.filter { !$0.settlement.isEmpty }
        let current = rows.filter { profileViewModel.isCurrentUser($0.user) }
        let others = rows.filter { !profileViewModel.isCurrentUser($0.user) }
        return (current + others).flatMap { participant in
            participant.settlement.map { settlement in
                OptimizationRecapPDFData(
                    fromName: participant.user.name,
                    toName: settlement.userPaid.name,
                    amount: settlement.amount
                )
            }
        }
    }

    private func statusText(for status: EventCardStatusEnum) -> String {
        switch status {
        case .debt: return "Should pay"
        case .credit: return "Should receive"
        case .settled: return "Settled"
        }
    }

    private func exportPDF() {
        let persons = orderedParticipants.map { participant in
            OptimizationPersonPDFData(
                name: participant.user.name,
                isCurrentUser: profileViewModel.isCurrentUser(participant.user),
                lent: participant.lent,
                debt: participant.debt,
                balance: participant.balance,
                statusText: statusText(for: participant.status)
            )
        }

        // The PDF always carries both recap views regardless of the on-screen
        // toggle: "Simplified" (netted) and "Detailed" (raw pairwise).
        let simplifiedRecap = recapPDF(from: eventViewModel.participantsBalance)
        let detailedRecap = recapPDF(from: eventViewModel.directSettlements)

        let expenses = (eventViewModel.selectedEvent?.expenses ?? [])
            .sorted { $0.dateOfCreation < $1.dateOfCreation }
            .map { expense in
            let isEqual = SplitMethod(rawValue: expense.splitMethod) == .equally
            let perPerson: Float? = (isEqual && !expense.participants.isEmpty)
                ? expense.price / Float(expense.participants.count)
                : nil
            return OptimizationExpensePDFData(
                name: expense.name,
                date: expense.dateOfCreation,
                payerName: expense.coverer.name,
                amount: expense.price,
                isEquallySplit: isEqual,
                equalSplitPerPerson: perPerson,
                participantNames: isEqual ? expense.participants.map { $0.name } : [],
                items: expense.items.map { item in
                    OptimizationExpenseItemPDFData(
                        name: item.itemName,
                        quantity: item.itemQuantity,
                        price: item.itemPrice,
                        assignees: item.assignees.map { assignee in
                            OptimizationAssigneePDFData(name: assignee.user.name, share: assignee.share)
                        }
                    )
                },
                additionalCharges: expense.additionalCharges.map { charge in
                    OptimizationAdditionalChargePDFData(
                        typeName: AdditionalChargeType(rawValue: charge.additionalChargeType)?.name ?? "Other",
                        amount: charge.amount
                    )
                }
            )
        }

        let data = SettlementOptimizationPDFExporter.generatePDF(from: SettlementOptimizationPDFData(
            eventName: eventViewModel.eventName,
            generatedByName: eventViewModel.userBalance.user.name,
            persons: persons,
            simplifiedRecap: simplifiedRecap,
            detailedRecap: detailedRecap,
            expenses: expenses
        ))

        let sanitizedEventName = eventViewModel.eventName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(sanitizedEventName)-optimization.pdf")

        guard (try? data.write(to: url)) != nil else { return }
        exportedPDF = ExportedPDF(url: url)
    }
}

/// Pill segmented control switching the recap between the netted "Simplified"
/// view and the raw "Detailed" pairwise view. Styled with the app's blue accent
/// tokens to match other interactive controls.
private struct RecapModeToggle: View {
    @Binding var isSimplified: Bool

    var body: some View {
        HStack (spacing: 0) {
            segment(title: "Simplified", isActive: isSimplified) {
                isSimplified = true
            }
            segment(title: "Detailed", isActive: !isSimplified) {
                isSimplified = false
            }
        }
        .padding(2)
        .background(.buttonBlueSelected)
        .clipShape(Capsule())
    }

    private func segment(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) { action() }
        }) {
            Text(title)
                .font(isActive ? .tabiBody2 : .tabiBody)
                .foregroundStyle(isActive ? .textWhite : .textBlue)
                .padding(.horizontal, .spacingRegular)
                .padding(.vertical, .spacingXSmall)
                .background(isActive ? Color.buttonBlue : .clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Identifiable wrapper so the share sheet can be driven by `.sheet(item:)`,
/// which guarantees the URL is available when the sheet body is built (unlike
/// `.sheet(isPresented:)`, which can present before the URL state has settled
/// and show a blank sheet).
private struct ExportedPDF: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    SettlementOptimizationView()
        .environment(Router())
}
