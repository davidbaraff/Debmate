//
//  RandomLockPool.swift
//  Debmate
//
//   Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation


/// A pool of locks.
///
/// This is useful to avoid creating thousands of different locks,
/// but ensure that the odds of any two instances using the same lock are
/// sufficiently minimal.
public class RandomLockPool {
    private let locks: [DispatchQueue]

    
    /// Initialize the pool to hold a specified number of locks.
    /// - Parameters:
    ///   - poolSize: The number of locks in the pool
    ///   - label: The label for each lock.
    public init(poolSize: Int, label: String) {
        locks = (0..<poolSize).map { DispatchQueue(label: "\(label).\($0)") }
    }
    
    /// Return a lock from the pool, chosen at random.
    /// - Returns: A lock.
    public func randomLock() -> DispatchQueue {
        let index = Int.self.random(in: 0..<locks.count)
        return locks[index]
    }
}
