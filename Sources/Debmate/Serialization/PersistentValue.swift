//
//  PersistentValue.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

#if !os(Linux)

import Foundation
import DebmateC
import SwiftUI

/// Wrap a value that stores itself persistently in UserDefaults.
@propertyWrapper
@MainActor
final public class PersistentValue<T : Equatable> : ObservableObject {
    public let key: String
    var refreshHelper: RefreshHelper!

    public var value: T {
        didSet { refreshHelper.updateNeeded() }
    }

    public var wrappedValue: T {
        get { value }
        set { value = newValue }
    }
    
    public var binding: Binding<T> {
        Binding(get: { self.value },
                set: { self.value = $0 })
    }

    public var projectedValue: PersistentValue {
        get { self }
    }

    /// Create a PersistentValue instance.
    ///
    /// - Parameters:
    ///   - key: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    public init(wrappedValue defaultValue: T, key keyName: String) {
        key = keyName
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [keyName : serializableDefaultValue]) }) {
            fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: keyName) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            value = defaultValue
        }

        refreshHelper = RefreshHelper {  [weak self] in
            MainActor.assumeIsolated {
                self?.flush()
                self?.objectWillChange.send()
            }
        }
    }
    
    /// Write value to UserDefaults immediately.
    private func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
}

#endif

