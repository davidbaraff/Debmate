//
//  SequenceExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation

public extension Sequence {
    /// Count number of elements matching a predicate
    ///
    /// - Parameter predicate: predicate function
    /// - Returns: Number of elements for which predicate is true
    func count_members(where predicate: (Self.Element) -> Bool) -> Int {
        return self.reduce(0) { predicate($1) ? $0 + 1 : $0 }
    }
    
    
    /// Return an enumerated array.
    /// - Returns: an array of elements [(0, self[0]), (1, self[1]), ...]
    func enumeratedArray() -> [(Int, Self.Element)] {
        self.enumerated().map { $0 }
    }
}
