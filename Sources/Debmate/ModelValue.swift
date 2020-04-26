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
public class ModelValue<T : Equatable> : ObservableObject {
    @Published public var value: T

    let key: String
    var primaryCancellable: Cancellable?
    var refreshHelper: RefreshHelper!
    
    public init(key keyName: String, defaultValue: T) {
        key = keyName
        value = defaultValue

        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [keyName : serializableDefaultValue]) }) {
            fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: key) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
            print("Init value with key \(key) to start with \(value)")
        }
        else {
            value = defaultValue
        }

        refreshHelper = RefreshHelper {  [weak self] in self?.flush() }
        primaryCancellable = objectWillChange.sink { [weak self] _ in self?.refreshHelper.updateNeeded() }
    }
    
    /// Immediately saves data to UserDefaults.
    private func flush() {
        print("Flushed value of key \(key) with value \(value)")
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
}
