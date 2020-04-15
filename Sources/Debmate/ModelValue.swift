//
//  ModelValue.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import DebmateC
import Combine

// Wrap a value into an observable object.
///
/// The ModelValue class is used to automatically save equatable
/// values to UserDefaults, while also allowing for anonymous notification
/// when the held value changes.  The value is stored as a published property
/// on the ModelValue<> object, which is an observable object.
///
@propertyWrapper
public class ModelValue<T : Equatable> : ObservableObject {
    @Published public var value: T
    let key: String
    
    public var wrappedValue: T {
        get { value }
        set {
            if value != newValue {
                value = newValue
                flush()
            }
        }
    }
    
    public var projectedValue: ModelValue {
        get { self }
    }

    public init(wrappedValue defaultValue: T, key keyName: String) {
        key = keyName
        value = defaultValue

        
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [key : serializableDefaultValue]) }) {
            fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: key) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            value = defaultValue
        }
    }
    
    /// Immediately saves data to UserDefaults.
    public func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
}
