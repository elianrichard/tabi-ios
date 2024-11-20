//
//  EventService.swift
//  Tabi Split
//
//  Created by Elian Richard on 20/11/24.
//

final class EventService {
    static let shared = ProfileService()
    
    private let apiClient: APIClient = APIService.shared
    private let tokenManager: TokenManaging = KeychainService.shared
    
//    func createEvent(request: CreateEventRequest) {
//        gu
//    }
}
