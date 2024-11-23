//
//  ExpenseService.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/11/24.
//

final class ExpenseService {
    static let shared = ExpenseService()
    private let apiClient: APIClient = APIService.shared
    
    func createExpense(event: EventData, expense: Expense) async throws {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let request: CreateExpenseRequest = CreateExpenseRequest(expense: expense)
        let _ : CreateEventResponse = try await apiClient.post(endpoint: "/expense/\(eventId)", body: request)
    }
}
