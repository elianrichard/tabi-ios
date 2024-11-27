//
//  ExpenseService.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/11/24.
//

final class ExpenseService {
    static let shared = ExpenseService()
    private let apiClient: APIClient = APIService.shared
    
    func createExpense(event: EventData, expense: Expense) async throws -> CreateExpenseResponse {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let request: CreateExpenseRequest = CreateExpenseRequest(expense: expense)
        let response : CreateExpenseResponse = try await apiClient.post(endpoint: "/expense/\(eventId)", body: request)
        
        return response
    }
    
    func deleteExpense(expense: Expense) async throws {
        guard let expenseId = expense.expenseId else { throw ExpenseAPIError.expenseIdNotFound }
        let _ : DeleteExpenseResponse = try await apiClient.delete(endpoint: "/expense/\(expenseId)")
    }
    
    func updateExpense(expense: Expense) async throws {
        guard let expenseId = expense.expenseId else { throw ExpenseAPIError.expenseIdNotFound }
        let request: UpdateExpenseRequest = UpdateExpenseRequest(expense: expense)
        let _ : UpdateExpenseResponse = try await apiClient.patch(endpoint: "/expense/\(expenseId)", body: request)
    }
}
