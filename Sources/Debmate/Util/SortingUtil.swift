//
//  SortingUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

extension Util {
    
    /// Compare two values, allowing for nil.
    ///
    /// - Parameters:
    ///   - lhs: lhs value
    ///   - rhs: rhs value
    ///   - nilComparesLast: if a nil value is greater than any-non nil value
    /// - Returns: if lhs is considered less than rhs
    static public func lessThanWithOptionals<T : Comparable>(_ lhs:T?, _ rhs:T?, nilComparesLast:Bool = true) -> Bool {
        if let lhs = lhs {
            if let rhs = rhs {
                return lhs < rhs
            }
            return nilComparesLast
        }
        
        return (rhs == nil) ? false : !nilComparesLast
    }
}


