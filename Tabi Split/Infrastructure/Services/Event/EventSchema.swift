//
//  EventSchema.swift
//  Tabi Split
//
//  Created by Elian Richard on 20/11/24.
//

import Foundation

struct CreateEventRequest: Codable {
    let name: String
//    let image: String
}

struct CreateEventResponse: Codable {
    let message: String
}
