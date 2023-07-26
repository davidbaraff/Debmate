//
//  SerialDispatcher.swift
//  
//
//  Created by David Baraff on 6/26/23.
//

/// A task-based mechanism for serial execution of work.
public actor SerialDispatcher {
    private var previousTask: Task<(), Error>?
    
    public init() {
        
    }

    /// Runs work after any perviously added work has completed.
    /// - Parameter work: work to be performed
    public func addWork(work: @Sendable @escaping () async throws -> Void) {
        previousTask = Task { [previousTask] in
            let _ = await previousTask?.result
            return try await work()
        }
    }
}

