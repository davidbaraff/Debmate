//
//  Performance.swift
//  Debmate
//
//  Copyright © 2017 David Baraff. All rights reserved.
//

import Foundation

internal extension Date {
    /// Seconds between the current time and the date recorded in this NSDate() object.
    ///
    /// The return value will be positive if the NSDate() object records a time earlier than
    /// the current time.
    var elapsedTime: Double {
        get {
            return -timeIntervalSinceNow
        }
    }
}

/// Time a block of code.
///
/// - Parameters:
///   - msg: Descriptive message printed after block completes.
///   - block: code to be timed
/// - Returns: return value of block
public func timed_execution<T>(_ msg: String, debug: Bool = true, block: () -> T) -> T {
    if !debug {
        return block()
    }

    let now = Date()
    let result = block()
    print("\(msg): \(now.elapsedTime) seconds")
    return result
}

/// Time a block of code.
///
/// - Parameters:
///   - msg: Descriptive message printed after block completes.
///   - block: code to be timed
/// - Returns: return value of block
public func timed_execution<T>(_ msg: String, debug: Bool = true, block: () throws -> T) throws -> T {
    if !debug {
        return try block()
    }

    let now = Date()
    let result = try block()
    print("\(msg): \(now.elapsedTime) seconds")
    return result
}

/// Returns the current time in seconds modulo 100 seconds.
public func debugging_date_stamp() -> Double {
    let seconds = Date.timeIntervalSinceReferenceDate
    return seconds.truncatingRemainder(dividingBy: 100.0)
}
