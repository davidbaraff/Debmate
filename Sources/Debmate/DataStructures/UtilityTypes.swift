//
//  UtilityTypes.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation

/// A hashable tuple of two elements.
public struct HashablePair<T1 : Hashable, T2 : Hashable> : Hashable {
    public init(_ first: T1, _ second: T2) {
        self.first = first
        self.second = second
    }
    
    /// First element.
    public let first: T1
    
    /// Second element.
    public let second: T2
}

/// Value wrapper to hold a weak reference.
public struct WeakRef<T : AnyObject> {
    /// Held weak reference.
    weak public var value: T?
    
    /// Construct a new instance holding value weakly.
    /// - Parameter value: Held value.
    public init(_ value: T) {
        self.value = value
    }
}

/// Hold a value/reference of any type.
///
/// This is mostly useful for placing an object in an Any which
/// cannot be cast back from an Any (e.g. types like CGImage).
public struct WrapForAny<T> {
    /// Held value.
    public let value: T
    
    
    /// Construct a new instance holding value
    /// - Parameter value: Held value
    public init(_ value: T) {
        self.value = value
    }
}
