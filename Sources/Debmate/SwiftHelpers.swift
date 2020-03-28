//
//  SwiftExtensions.swift
//  Debmate
//
//  Copyright © 2020 deb. All rights reserved.
//

import Foundation

public func all<ST : Sequence>(_ sequence:ST, where predicate:(ST.Element) -> Bool) -> Bool {
    for e in sequence {
        if !predicate(e) {
            return false
        }
    }
    return true
}

/// Check if all elements of a sequence of Bools are true.
///
/// - Parameters:
///   - sequence: element sequence
/// - Returns: true if false is not found in the sequence.
///
/// Note: all() always returns true for the empty sequence.
public func all<ST : Sequence>(_ sequence:ST) -> Bool where ST.Element == Bool {
    for e in sequence {
        if !e {
            return false
        }
    }
    return true
}

/// Check if any element of a collection satifises a predicate
///
/// - Parameters:
///   - sequence: element sequence
///   - predicate: predicate function
/// - Returns: true only if some element of the sequence satisifies the predicate.
///
/// Note: any() always returns false on an empty sequence.
public func any<ST : Sequence>(_ sequence: ST, where predicate: (ST.Element) -> Bool) -> Bool {
    for e in sequence {
        if predicate(e) {
            return true
        }
    }
    return false
}

/// Check if any element of a sequence of Bools is true
///
/// - Parameters:
///   - sequence: element sequence
/// - Returns: true if true is  found in the sequence.
///
/// Note: any() always returns false for the empty sequence.
public func any<ST : Sequence>(_ sequence:ST) -> Bool where ST.Element == Bool {
    for e in sequence {
        if e {
            return true
        }
    }
    return false
}


/// A hashable tuple of two elements.
public struct HashablePair<T1 : Hashable, T2 : Hashable> : Hashable {
    public init(_ first: T1, _ second: T2) {
        self.first = first
        self.second = second
    }
    
    public let first: T1
    public let second: T2
}

public struct WeakRef<T : AnyObject> {
    weak public var value: T?
    
    public init(_ value: T) {
        self.value = value
    }
}
