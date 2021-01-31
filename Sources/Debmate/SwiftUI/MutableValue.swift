//
//  MutableValue.swift
//  Debmate
//
//  Created by David Baraff on 1/24/21.
//

import Combine


/// Class holding a mutable value.
///
/// This class is useful for SwiftUI View classes that need mutable state.
public class MutableValue<T> {
    private var value: T?
    
    /// Class is initialized to hold nil.
    /// Attempts to access the value will cause a fatal error until update() is called.
    public init() {
    }

    /// Class is initialized to hold initialValue.
    public init(_ initialValue: T) {
        value = initialValue
    }

    
    /// Set a new value for this object.
    /// - Parameter newValue: new value being held
    public func update(_ newValue: T) {
        value = newValue
    }
    
    /// Returns the held value
    /// - Returns: the current value held by the class.
    ///
    /// Warning:
    ///    This function will crash if no value has been set for this object.
    public func callAsFunction() -> T {
        guard let value = value else {
            let descr = String(describing: type(of: T.self))
            fatalErrorForCrashReport("MutableValue<\(descr)> is holding nil")
        }
        return value
    }
}
