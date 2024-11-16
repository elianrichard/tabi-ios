//
//  UserDefaultsService.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

import Foundation

public enum UserDefaultKeys: String {
    case currentUserDetails
}

class UserDefaultsService {
    static let shared = UserDefaultsService() // Singleton instance
    
    private let defaults = UserDefaults.standard
    
    private init() {} // Private initializer to prevent instantiation

    // Generic method to set a value
    func setValue<T: Codable>(_ value: T, forKey key: UserDefaultKeys) {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key.rawValue)
        } else {
            print("Failed to encode and save value for key: \(key)")
        }
    }

    // Generic method to get a value
    func getValue<T: Codable>(forKey key: UserDefaultKeys, ofType type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    // Method for storing basic types (String, Int, Bool, etc.)
    func setBasicValue(_ value: Any, forKey key: UserDefaultKeys) {
        defaults.set(value, forKey: key.rawValue)
    }

    // Method for retrieving basic types (String, Int, Bool, etc.)
    func getBasicValue(forKey key: UserDefaultKeys) -> Any? {
        return defaults.object(forKey: key.rawValue)
    }
}
