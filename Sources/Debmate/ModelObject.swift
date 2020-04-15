//
//  ObservableObjectData.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import DebmateC
import Combine

/// Class for representing model data tied to state saving.
///
/// The ModeObject class is used to automatically save observable
/// objects to UserDefaults, while also allowing for anonymous notification when any
/// (published) )member of the observable object changes.
///
@propertyWrapper
public class ModelObject<T : ObservableObject> {
    let key: String
    var primaryCancellable: Cancellable?
    var refreshHelper: RefreshHelper!

    public var value: T 

    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            flush()
            watchValue()
        }
    }
    
    public var projectedValue: ModelObject {
        get { self }
    }

    /// Create a ModelObject instance.
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

        watchValue()
        refreshHelper = RefreshHelper {  [weak self] in self?.flush() }
    }
    
    private var deferredWriteLevel = 0
    
    /// Group updates into one.
    /// - Parameter block: update code
    ///
    /// Upon completion of block(), a notice is emitted and data is synchronized to UserDefaults
    /// if value has been changed.
    ///
    /// This function should only be called on the main dispatch queue.
    public func batchUpdate(block: () -> ()) {
        deferredWriteLevel += 1
        block()
        deferredWriteLevel -= 1
        flush()
    }
    
    /// Write value to UserDefaults immediately.
    public func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
    
    private func watchValue() {
        primaryCancellable?.cancel()
        primaryCancellable = value.objectWillChange.sink { [weak self] _ in self?.refreshHelper.updateNeeded() }
    }
}
