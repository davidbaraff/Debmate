//
//  DictionaryExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation

public extension Dictionary {
    public init(overwriting items: [(Self.Key, Self.Value)]) {
        self = Dictionary(items) { first, second in second }
    }
    
    /// Merge in a sequence
    ///
    /// - Parameter tuples: later tuples overwrite earlier tuples in the merge
    mutating func overwritingMerge<ST : Sequence>(_ tuples: ST) where ST.Element == (Key, Value)  {
        self.merge(tuples, uniquingKeysWith: { $1 })
    }
    
    /// Merge in another dictionary
    ///
    /// - Parameter dictionary: values in dictionary are merged on top of self
    mutating func overwritingMerge(_ dictionary: Dictionary) {
        self.merge(dictionary, uniquingKeysWith: { $1 })
    }
}
