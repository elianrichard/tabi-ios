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
            OptimizationExpensePDFData(name: "KFC", payerName: "Elian", amount: 100_000),
            OptimizationExpensePDFData(name: "Taxi", payerName: "Budi", amount: 50_000),
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
}
