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

public extension Array where Element : Equatable {
    
    /// Add an item to the front of array and remove duplicates of that item.
    /// - Parameters:
    ///   - element: element to be added
    ///   - maxCount: maximum length of resulting array
    /// - Returns: A new array with element at the front, and of maximum length maxCount.
    mutating func addToFrontRemovingDuplicates(_ element: Element, maxCount: Int? = nil) {
        self = [element] + self.filter { $0 != element }
        if let maxCount = maxCount,
           count > maxCount  {
           removeLast(count - maxCount)
        }
    }
}
