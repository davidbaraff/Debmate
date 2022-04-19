//
//  ResultExtensions.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

import Foundation

public extension Result where Failure == Error {
    /// Awaits the passed in work function.
    init(_ work:  (() async throws -> Success)) async {
        do {
            self = .success( try await work())
        } catch {
            self = .failure(error)
        }
    }
    
    var succeeded: Bool {
        if case .success = self { return true }
        return false
    }
    
    var failed: Bool {
        !succeeded
    }
}
