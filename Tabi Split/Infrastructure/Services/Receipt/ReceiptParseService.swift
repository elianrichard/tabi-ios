//
//  ReceiptParseService.swift
//  Tabi Split
//
//  Sends the on-device OCR lines plus the heuristic draft parse to the backend,
//  which asks an LLM (OpenRouter) to refine them into a structured receipt.
//

import Foundation

// MARK: - Wire models (match the Go model.Receipt* schema)

struct ReceiptDraftItem: Codable {
    let name: String
    let quantity: Int
    let unit_price: Double
    let line_total: Double
}

struct ReceiptDraftCharge: Codable {
    let type: String   // "tax" | "service" | "discount" | "other"
    let name: String
    let amount: Double
}

struct ReceiptDraft: Codable {
    let items: [ReceiptDraftItem]
    let additional_charges: [ReceiptDraftCharge]
    let subtotal: Double
    let total: Double
    let currency: String
}

struct ReceiptParseRequest: Codable {
    let lines: [String]
    let draft: ReceiptDraft?
}

/// The refined receipt. Same shape as the request draft.
typealias ReceiptParseResponse = ReceiptDraft

final class ReceiptParseService {
    static let shared = ReceiptParseService()
    private let apiClient: APIClient = APIService.shared

    /// Refines OCR lines + an on-device draft into a structured receipt.
    func parse(lines: [String], draft: ReceiptDraft?) async throws -> ReceiptParseResponse {
        let request = ReceiptParseRequest(lines: lines, draft: draft)
        let response: ReceiptParseResponse = try await apiClient.post(endpoint: "/receipt/parse", body: request)
        return response
    }
}
