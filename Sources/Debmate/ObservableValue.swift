//
//  ObservableValueData.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import DebmateC
import Combine
import SwiftUI

/// Class for representing model data tied to state saving.
///
/// The ObservableValueData class is used to automatically save equable
/// values to UserDefaults, while also allowing for anonymous notification
/// the held value changes.  The value is stored as a published property
/// on the ObservableValueData<> object, which is an observable object.
///
public class ObservableValueData<T : Equatable> : ObservableObject {
    let keyName: String

    @Published public var value: T {
        didSet {
            if deferredWriteLevel == 0 && value != oldValue {
                UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
            }
        }
    }

    /// Specify a closure to be run when the value of the control changes.
    ///
    /// The returned Cancelable must be retained for the closure to be called when the value changes.
    public func listen(receiveValue: @escaping (T) -> ()) -> Cancellable {
        return objectWillChange.sink { _ in DispatchQueue.main.async { receiveValue(self.value) } }
    }
    
    /// Specify a closure to be run when the value of the control changes.
    ///
    /// Tthis form immediately invokes the closure if callNow is true.
    ///
    /// The returned Cancelable must be retained for the closure to be called when the value changes.
    public func listen(callNow: Bool, receiveValue: @escaping (T) -> ()) -> Cancellable {
        let result = listen(receiveValue: receiveValue)
        if callNow {
            receiveValue(value)
        }
        return result
    }
    
    /// Create a PureModelData instance.
    ///
    /// - Parameters:
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    public init(_ keyName: String, defaultValue: T) {
        self.keyName = keyName
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [keyName : serializableDefaultValue]) }) {
            if (defaultValue as? DiskCachable) == nil {
                fatalErrorForCrashReport("Type \(String(describing: T.self)) does not conform to DiskCachable")
            }
            else {
                fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
            }
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: keyName) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            value = defaultValue
        }
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
        let oldValue = value
        deferredWriteLevel += 1
        block()
        deferredWriteLevel -= 1

        if value != oldValue {
            UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
        }
    }
}


// Wrap a value into an observable object.
///
/// The ObservableValueData class is used to automatically save equable
/// values to UserDefaults, while also allowing for anonymous notification
/// the held value changes.  The value is stored as a published property
/// on the ObservableValueData<> object, which is an observable object.
///
@propertyWrapper
public class ObservableValue<T> : ObservableObject {
    @Published public var value: T
    
    public var wrappedValue: T {
        get { value }
        set { value = newValue }
    }

    public init(wrappedValue: T) {
        value = wrappedValue
    }

/*
    public var value: Published<T> {
        _curValue
    }
*/
    
    public var projectedValue: ObservableValue {
      get { self }
    }
}
