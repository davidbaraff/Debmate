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

public extension Sequence {
    /// Count number of elements matching a predicate
    ///
    /// - Parameter predicate: predicate function
    /// - Returns: Number of elements for which predicate is true
    func count_members(where predicate: (Self.Element) -> Bool) -> Int {
        return self.reduce(0) { predicate($1) ? $0 + 1 : $0 }
    }
}
