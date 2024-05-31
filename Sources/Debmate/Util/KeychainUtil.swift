//
//  KeychainUtil.swift
//  Debmate
//
//  Created by David Baraff on 5/8/24.
//

import Foundation

extension Util {
    @discardableResult
    /// Write a string value to the keychain.
    /// - Parameters:
    ///   - bundleName: bundle name to store secret under
    ///   - serviceName: service name to store secret under
    ///   - secret: secret
    /// - Returns: True if the value was stored, false otherwise.
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
}

