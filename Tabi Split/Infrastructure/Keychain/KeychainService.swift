//
//  KeychainService.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation
import Security

protocol KeychainStoring {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data
    func delete(forKey key: String) throws
}

protocol TokenManaging {
    func saveAccessToken(_ token: String) throws
    func saveRefreshToken(_ token: String) throws
    func getAccessToken() throws -> String
    func getRefreshToken() throws -> String
    func clearTokens() throws
}

final class KeychainService {
    static let shared = KeychainService()
    private let service: String
    
    private init() {
        self.service = Bundle.main.bundleIdentifier ?? "com.your.app"
    }
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case dataConversionError
        case itemNotFound
    }
    
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }
}

extension KeychainService: KeychainStoring {
    func save(_ data: Data, forKey key: String) throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecValueData as String: data as AnyObject
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let attributes: [String: AnyObject] = [
                kSecValueData as String: data as AnyObject
            ]
            
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unknown(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    func load(forKey key: String) throws -> Data {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.dataConversionError
        }
        
        return data
    }
    
    func delete(forKey key: String) throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}

extension KeychainService: TokenManaging {
    func saveAccessToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        try save(data, forKey: Keys.accessToken)
    }
    
    func saveRefreshToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        try save(data, forKey: Keys.refreshToken)
    }
    
    func getAccessToken() throws -> String {
        let data = try load(forKey: Keys.accessToken)
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        return token
    }
    
    func getRefreshToken() throws -> String {
        let data = try load(forKey: Keys.refreshToken)
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        return token
    }
    
    func clearTokens() throws {
        try delete(forKey: Keys.accessToken)
        try delete(forKey: Keys.refreshToken)
    }
}
