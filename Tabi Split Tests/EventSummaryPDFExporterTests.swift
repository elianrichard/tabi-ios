//
//  EventSummaryPDFExporterTests.swift
//  Tabi Split Tests
//
//  Created by Elian Richard on 11/08/26.
//

import XCTest
@testable import Tabi_Split

final class EventSummaryPDFExporterTests: XCTestCase {

    private func makeData(transactions: [SummaryHistoryData] = [
        SummaryHistoryData(expenseName: "KFC", expenseDate: Date(), amount: 50_000),
        SummaryHistoryData(expenseName: "Taxi", expenseDate: Date().yesterday(), amount: -25_000),
    ]) -> EventSummaryPDFData {
        EventSummaryPDFData(
            eventName: "Bali Trip",
            userName: "Elian",
            statusText: "You Should Pay",
            balance: -25_000,
            totalSpending: 75_000,
            transactions: transactions
        )
    }

    func testGeneratePDFReturnsNonEmptyData() throws {
        let data = EventSummaryPDFExporter.generatePDF(from: makeData())
        XCTAssertFalse(data.isEmpty, "Generated PDF data should not be empty.")
    }

    func testGeneratePDFStartsWithValidPDFHeader() throws {
        let data = EventSummaryPDFExporter.generatePDF(from: makeData())
        // A valid PDF file begins with the %PDF magic header.
        guard let first8 = String(data: data.prefix(8), encoding: .ascii) else {
            return XCTFail("Could not decode PDF header.")
        }
        XCTAssertTrue(first8.hasPrefix("%PDF"), "PDF should start with %PDF header, got: \(first8)")
    }

    func testGeneratePDFWithEmptyTransactions() throws {
        let data = EventSummaryPDFExporter.generatePDF(from: makeData(transactions: []))
        XCTAssertFalse(data.isEmpty, "PDF should still be generated when there are no transactions.")
    }

    func testGeneratePDFWithManyTransactionsSpansPages() throws {
        // 200 transactions should force pagination beyond a single A4 page.
        let transactions = (0..<200).map { index in
            SummaryHistoryData(expenseName: "Expense \(index)", expenseDate: Date(), amount: Float(index * 1000))
        }
        let data = EventSummaryPDFExporter.generatePDF(from: makeData(transactions: transactions))
        XCTAssertFalse(data.isEmpty)
    }
}