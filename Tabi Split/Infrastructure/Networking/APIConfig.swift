//
//  APIConfig.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

struct APIConfig {
    let baseURL: String
    let unauthorizedMessages: [String]
    
    static let `default` = APIConfig(
        baseURL: ENV.BASE_API_URL,
        unauthorizedMessages: ["Is not authorized", "Access is denied"]
    )
}
