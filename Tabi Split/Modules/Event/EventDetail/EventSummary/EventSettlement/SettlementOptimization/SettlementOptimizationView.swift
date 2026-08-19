//
//  SettlementOptimizationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementOptimizationView: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel

    @State private var contentSize: CGSize = .zero
    @State private var exportedPDF: ExportedPDF?

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
                VStack (alignment: .leading) {
                    Text("Recapitulation")
                        .font(.tabiHeadline)
                    ScrollView (showsIndicators: false) {
                        VStack (spacing: .spacingMedium) {
                            ForEach (eventViewModel.participantsBalance) { data in
                                OptimizationRecapCard(recapData: data)
                            }
                        }
                        .padding(.vertical, .spacingTight)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    contentSize = geo.size
                                }
                            }
                        )
                    }
                    .padding(.horizontal, .spacingRegular)
                    .frame(maxWidth: .infinity, maxHeight: contentSize.height)
//                    .frame(height: contentSize.height)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radiusLarge)
                            .strokeBorder(.uiGray, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                    .padding(1)
                }
                .padding([.bottom, .horizontal])
            }
            Spacer()
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

        let recap = orderedParticipants.flatMap { participant in
            participant.settlement.map { settlement in
                OptimizationRecapPDFData(
                    fromName: participant.user.name,
                    toName: settlement.userPaid.name,
                    amount: settlement.amount
                )
            }
        }

        let expenses = (eventViewModel.selectedEvent?.expenses ?? []).map { expense in
            let isEqual = SplitMethod(rawValue: expense.splitMethod) == .equally
            let perPerson: Float? = (isEqual && !expense.participants.isEmpty)
                ? expense.price / Float(expense.participants.count)
                : nil
            return OptimizationExpensePDFData(
                name: expense.name,
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
            recap: recap,
            expenses: expenses
        ))

        let sanitizedEventName = eventViewModel.eventName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(sanitizedEventName)-optimization.pdf")

        guard (try? data.write(to: url)) != nil else { return }
        exportedPDF = ExportedPDF(url: url)
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
        .environment(Routes())
}
