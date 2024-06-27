//
//  ModelState.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

#if !os(Linux)

import Foundation
import DebmateC
import Combine

/// Class for representing model data tied to state saving.
///
/// The ModeState class is used to automatically save observable
/// objects to UserDefaults, while also allowing for anonymous notification when any
/// (published) )member of the observable object changes.
///
@propertyWrapper
public class ModelState<T : ObservableObject> {
    let key: String
    var primaryCancellable: Cancellable?
    var refreshHelper: RefreshHelper!

    public var value: T 

    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            refreshHelper.updateNeeded()
            watchValue()
        }
    }
    
    public var projectedValue: ModelState {
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
    
    /// Write value to UserDefaults immediately.
    private func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
    
    private func watchValue() {
        primaryCancellable?.cancel()
        primaryCancellable = value.objectWillChange.sink { [weak self] _ in self?.refreshHelper.updateNeeded() }
    }
}
#endif

