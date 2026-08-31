//
//  UserDefaultsService.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

import Foundation

public enum UserDefaultKeys: String {
    case currentUserDetails, onboardingStatus
}

class UserDefaultsService {
    static let shared = UserDefaultsService()

    private let defaults = UserDefaults.standard

    private init() {}

    func setValue<T: Codable>(_ value: T, forKey key: UserDefaultKeys) {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key.rawValue)
        } else {
            print("Failed to encode and save value for key: \(key)")
        }
    }

    func getValue<T: Codable>(forKey key: UserDefaultKeys, ofType type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    func setBasicValue(_ value: Any, forKey key: UserDefaultKeys) {
        defaults.set(value, forKey: key.rawValue)
    }

    func getBasicValue(forKey key: UserDefaultKeys) -> Any? {
        return defaults.object(forKey: key.rawValue)
    }
    
    func deleteKeyValue(forKey key: UserDefaultKeys) {
        defaults.removeObject(forKey: key.rawValue)
    }
}
