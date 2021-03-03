//
//  AtomicIntegerSequence.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation

/// A threadsafe monotonically increasing sequence.
public class AtomicIntegerSequence {
    let lock = DispatchQueue(label: "com.debmate.AtomicIntegerSequence.lock")
    var counter = 0

    public init() {
    }
    
    /// Each access to next returns the next value in the sequence.
    public var next: Int {
        lock.sync {
            counter += 1
            return counter
        }
    }
}
