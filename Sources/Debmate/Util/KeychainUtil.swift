//
//  KeychainUtil.swift
//  Debmate
//
//  Created by David Baraff on 5/8/24.
//

import Foundation

extension Util {
    
    /// Securely write to keychain
    /// - Parameters:
    ///   - data: data to be stored
    ///   - keychainAccount: uniquely named keychain account
    /// - Returns: true if the write could be performed.
    @discardableResult
    static public func writeToKeychain(data: Data, keychainAccount: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    
    /// Clear item from keychain
    /// - Parameter keychainAccount: uniquely named keychain account
    static public func clearFromKeychain(keychainAccount: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    
    /// Read (securely) from keychain
    /// - Parameter keychainAccount: uniquely named keychain account
    /// - Returns: data, if found
    static public func readFromKeychain(keychainAccount: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            if let data =  result as? Data {
                return data
            }
            throw GeneralError("error reading \(keychainAccount): result had type \(type(of: result))")
        case errSecItemNotFound:
            return nil
        default:
            throw GeneralError("error reading \(keychainAccount) from keychain: \(status)")
        }
    }
    
    /// Write a string value to the keychain.
    /// - Parameters:
    ///   - bundleName: bundle name to store secret under
    ///   - serviceName: service name to store secret under
    ///   - secret: secret
    /// - Returns: True if the value was stored, false otherwise.
    @discardableResult
    static public func writeToKeychain(bundleName: String, serviceName: String, secret: String) -> Bool {
        let query = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: bundleName,
               kSecAttrAccount: serviceName,
                 kSecValueData: secret.asData] as CFDictionary
        
        SecItemDelete (query)
        SecItemDelete(query)
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }
    
    /// Read back a string from the keychain.
    /// - Parameters:
    ///   - bundleName: bundle secret was stored under
    ///   - serviceName: service secret was stored under
    /// - Returns: secret (if found)
    static public func readFromKeychain(bundleName: String, serviceName: String) -> String? {
        let query = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: bundleName,
               kSecAttrAccount: serviceName,
                kSecReturnData: true] as CFDictionary
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        guard status == errSecSuccess else {
            return nil
        }
        
        return (item as! Data).asUTF8String
    }
    
    /// Write a string value to a shared keychain.
    /// - Parameters:
    ///   - appGroupName: the shared app group of the keychain
    ///   - tableName: the table to store the value under
    ///   - keyName: the specific key name in the table
    ///   - secret: secret
    /// - Returns: True if the value was stored, false otherwise.
    @discardableResult
    static public func writeToSharedKeychain(appGroupNameName: String, tableName: String, keyName: String, secret: String) -> Bool {
        let query = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: keyName,
               kSecAttrAccount: tableName,
           kSecAttrAccessGroup: appGroupNameName,
        kSecAttrSynchronizable: true,
                 kSecValueData: secret.asData] as CFDictionary
        
        SecItemDelete(query)
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }
    
    /// Read back a string from the shared keychain.
    /// - Parameters:
    ///   - appGroupName: the shared app group of the keychain
    ///   - tableName: the table to store the value under
    ///   - keyName: the specific key name in the table
    /// - Returns: secret (if found)
    static public func readFromSharedKeychain(appGroupNameName: String, tableName: String, keyName: String) -> String? {
        let query = [kSecClass: kSecClassGenericPassword,
               kSecAttrService: keyName,
               kSecAttrAccount: tableName,
           kSecAttrAccessGroup: appGroupNameName,
        kSecAttrSynchronizable: kSecAttrSynchronizableAny,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne] as CFDictionary
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        guard status == errSecSuccess else {
            return nil
        }
        
        return (item as! Data).asUTF8String
    }
}

