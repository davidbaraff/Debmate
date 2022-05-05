//
//  TaskExtensions.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
