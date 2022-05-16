//
//  ScopedValue.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

#if !os(Linux)

import Foundation
import DebmateC
import SwiftUI

/// Helper class used in conjunction with ScopedValue.
public class ScopedValuePrefix : ObservableObject {
    /// Prefix string
    public let prefix: String

    /// True if the prefix is empty.
    public var isEmpty: Bool { prefix.isEmpty }

    /// Construct a new instance
    /// - Parameter prefix: prefix string
    public init(prefix: String = "") {
        self.prefix = prefix
    }
    
    /// Read from a ScopedValue instance.
    /// - Parameter scopedValue: ScopedValue instance being read from
    /// - Returns: current value.
    public func callAsFunction<T>(_ scopedValue: ScopedValue<T>) -> T {
        return scopedValue.readValue(prefix: self)
    }

    
    /// Save a value in a ScopedValue instance.
    /// - Parameters:
    ///   - scopedValue: ScopedValue instance being written to
    ///   - value: value to be saved
    public func callAsFunction<T>(set scopedValue: ScopedValue<T>, with value: T) {
        scopedValue.saveValue(prefix: self, value: value)
    }
}

/// Store a value that stores itself persistently in UserDefaults, applying
/// prefix scoping for the key name (e.g. for per-window settings).
public class ScopedValue<T : Equatable> {
    var key: String
    var refreshHelper: RefreshHelper!
    var initialized = false
    
    private var value: T
    
    func readValue(prefix: ScopedValuePrefix) -> T {
        if !initialized {
            initialized = true
            key = "\(prefix.prefix):\(key)"
            if let storedValue = UserDefaults.standard.object(forKey: key),
               let decodedValue: T = decodeFromCachableAny(storedValue) {
                value = decodedValue
            }
        }
        
        return value
    }

    func saveValue(prefix: ScopedValuePrefix, value: T) {
        self.value = value
        if !initialized {
            initialized = true
            key = "\(prefix.prefix):\(key)"
        }
        refreshHelper.updateNeeded()
    }

    /// Create a ScopedValue instance.
    ///
    /// - Parameters:
    ///   - key: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    /// In order to read/write a ScopedValue instance, you must obtain a ScopedValuePrefix
    /// instance.  Given an instance named prefix, the usage is:
    ///
    ///     let currentValue = scopedPrefix(scopedValue)
    ///     ...
    ///     scopedPrefix(set scopedValue: with: 37)
    public init(key keyName: String, defaultValue: T) {
        key = keyName
        value = defaultValue
        refreshHelper = RefreshHelper {  [weak self] in self?.flush() }

        let serializableDefaultValue = encodeAsCachableAny(defaultValue)

        // catch type errors immediately
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: ["__testCanary__scopedValue___" : serializableDefaultValue]) }) {
            fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
        }
    }
    
    // Write value to UserDefaults immediately.
    private func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
}
#endif

