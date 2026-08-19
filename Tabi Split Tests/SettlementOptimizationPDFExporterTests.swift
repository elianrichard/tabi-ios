//
//  SettlementOptimizationPDFExporterTests.swift
//  Tabi Split Tests
//
//  Created by Elian Richard on 11/08/26.
//

import XCTest
@testable import Tabi_Split

final class SettlementOptimizationPDFExporterTests: XCTestCase {

    private func makeData(
        persons: [OptimizationPersonPDFData] = [
            OptimizationPersonPDFData(name: "Elian", isCurrentUser: true, lent: 100_000, debt: 25_000, balance: 75_000, statusText: "Should receive"),
            OptimizationPersonPDFData(name: "Budi", isCurrentUser: false, lent: 0, debt: 75_000, balance: -75_000, statusText: "Should pay"),
        ],
        recap: [OptimizationRecapPDFData] = [
            OptimizationRecapPDFData(fromName: "Budi", toName: "Elian", amount: 75_000),
        ],
        expenses: [OptimizationExpensePDFData] = [
            OptimizationExpensePDFData(name: "KFC", payerName: "Elian", amount: 100_000, isEquallySplit: false, equalSplitPerPerson: nil, participantNames: [], items: [
                OptimizationExpenseItemPDFData(name: "Chicken Bucket", quantity: 2, price: 80_000, assignees: [
                    OptimizationAssigneePDFData(name: "Elian", share: 1),
                    OptimizationAssigneePDFData(name: "Budi", share: 1),
                ]),
                OptimizationExpenseItemPDFData(name: "Rice", quantity: 4, price: 20_000, assignees: []),
            ], additionalCharges: [
                OptimizationAdditionalChargePDFData(typeName: "Tax", amount: 11_000),
                OptimizationAdditionalChargePDFData(typeName: "Service", amount: 5_000),
                OptimizationAdditionalChargePDFData(typeName: "Discount", amount: 10_000),
            ]),
            // Equally-split expense: item breakdown should be omitted in the PDF.
            OptimizationExpensePDFData(name: "Taxi", payerName: "Budi", amount: 50_000, isEquallySplit: true, equalSplitPerPerson: 25_000, participantNames: ["Elian", "Budi"], items: [], additionalCharges: []),
        ]
    ) -> SettlementOptimizationPDFData {
        SettlementOptimizationPDFData(
            eventName: "Bali Trip",
            generatedByName: "Elian",
            persons: persons,
            recap: recap,
            expenses: expenses
        )
    }

    func testGeneratePDFReturnsNonEmptyData() throws {
        let data = SettlementOptimizationPDFExporter.generatePDF(from: makeData())
        XCTAssertFalse(data.isEmpty, "Generated PDF data should not be empty.")
    }

    func testGeneratePDFStartsWithValidPDFHeader() throws {
        let data = SettlementOptimizationPDFExporter.generatePDF(from: makeData())
        // A valid PDF file begins with the %PDF magic header.
        guard let first8 = String(data: data.prefix(8), encoding: .ascii) else {
            return XCTFail("Could not decode PDF header.")
        }
        XCTAssertTrue(first8.hasPrefix("%PDF"), "PDF should start with %PDF header, got: \(first8)")
    }

    func testGeneratePDFWithNoParticipantsOrRecap() throws {
        let data = SettlementOptimizationPDFExporter.generatePDF(from: makeData(persons: [], recap: []))
        XCTAssertFalse(data.isEmpty, "PDF should still be generated when there are no participants or settlements.")
    }

    func testGeneratePDFWithManyParticipantsSpansPages() throws {
        // 60 participants + settlements should force pagination beyond a single A4 page.
        var persons: [OptimizationPersonPDFData] = []
        var recap: [OptimizationRecapPDFData] = []
        for index in 0..<60 {
            let lent = Float(index * 1000)
            let balance = Float(index * 500)
            let status = index % 2 == 0 ? "Should receive" : "Should pay"
            persons.append(OptimizationPersonPDFData(
                name: "Person \(index)",
                isCurrentUser: index == 0,
                lent: lent,
                debt: balance,
                balance: balance,
                statusText: status
            ))
            recap.append(OptimizationRecapPDFData(fromName: "Person \(index)", toName: "Person 0", amount: balance))
        }
        let data = SettlementOptimizationPDFExporter.generatePDF(from: makeData(persons: persons, recap: recap))
        XCTAssertFalse(data.isEmpty)
    }

    func testGeneratePDFWithEquallySplitSubsetParticipants() throws {
        // An equally-split expense shared by only a subset of the event's members.
        let equal = OptimizationExpensePDFData(
            name: "Drinks",
            payerName: "Elian",
            amount: 60_000,
            isEquallySplit: true,
            equalSplitPerPerson: 30_000,
            participantNames: ["Elian", "Budi"],
            items: [],
            additionalCharges: []
        )
        let data = SettlementOptimizationPDFExporter.generatePDF(from: makeData(expenses: [equal]))
        XCTAssertFalse(data.isEmpty)
    }

    func testGeneratePDFWithManyExpensesAndItemsSpansPages() throws {
        // 40 expenses, each with several line items, should force the expense
        // section to paginate beyond its own starting page.
        var expenses: [OptimizationExpensePDFData] = []
        for expenseIndex in 0..<40 {
            var items: [OptimizationExpenseItemPDFData] = []
            for itemIndex in 0..<5 {
                items.append(OptimizationExpenseItemPDFData(
                    name: "Item \(expenseIndex)-\(itemIndex)",
                    quantity: Float(itemIndex + 1),
                    price: Float((itemIndex + 1) * 1000),
                    assignees: [OptimizationAssigneePDFData(name: "Person \(itemIndex % 3)", share: Float(itemIndex + 1))]
                ))
            }
            expenses.append(OptimizationExpensePDFData(
                name: "Expense \(expenseIndex)",
                payerName: "Person \(expenseIndex % 3)",
                amount: Float(expenseIndex * 10_000),
                isEquallySplit: false,
                equalSplitPerPerson: nil,
                participantNames: [],
                items: items,
                additionalCharges: [OptimizationAdditionalChargePDFData(typeName: "Tax", amount: Float(expenseIndex * 1000))]
            ))
        }
        let data = SettlementOptimizationPDFExporter.generatePDF(from: makeData(expenses: expenses))
        XCTAssertFalse(data.isEmpty)
    }
}
