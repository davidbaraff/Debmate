//
//  SchedulingUtil.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation

fileprivate var coalesceSet = Set<String>()
fileprivate var namedTimers = [String : Timer]()


/// Sleep (convenience call to Dispatch.usleep).
/// - Parameter seconds: sleep duration
public func sleep(seconds: Double) {
#if !os(Linux)
    Dispatch.usleep(useconds_t(1e6 * seconds))
#endif
}

extension Util {
    /// Coalesce invocations of future work into a single execution.
    ///
    /// - Parameters:
    ///   - key: A unique key for each distinct item of work
    ///   - work: closure to be executed
    ///
    /// Use this function when work needs to be scheduled in the future, and
    /// no new scheduling of the same work should be done until the current work
    /// actually executes.  The usage is as follows:
    /// ````
    ///     Debmate.Util.coalesce(begin: "networkChange") {
    ///         DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    ///             Debmate.Util.coalesce(end: "networkChange")
    ///             << actual work to be done >>
    ///         }
    ///     }
    /// ````
    ///
    /// Note that the end of the coalesce must use the same key, and be performed
    /// in the future when the operation actually takes place.
    static public func coalesce(begin key: String, work:() -> Void) {
        if !coalesceSet.contains(key) {
            coalesceSet.insert(key)
            work()
        }
    }
    
    /// End a coalesce operation.
    ///
    /// - Parameter key: key name matching coalesce(begin:) call.
    static public func coalesce(end key: String) {
        coalesceSet.remove(key)
    }
    
    
    /// Schedule a task to be run on the main queue.
    ///
    /// - Parameters:
    ///   - name: name for task
    ///   - delay: delay in seconds before task is run
    ///   - task: code to be executed
    ///
    /// A task can be canceled by calling cancelScheduledTask().
    static public func scheduleTask(name: String, delay: Double, task: @escaping () -> ()) {
        if let timer = namedTimers[name] {
            timer.stop()
        }

        let timer = Timer(task)
        namedTimers[name] = timer
        timer.start(once: delay)
    }
    
    
    /// Cancel a previously scheduled task.
    ///
    /// - Parameter name: name of scheduled task
    static public func cancelScheduledTask(name: String) {
        if let timer = namedTimers[name] {
            timer.stop()
            namedTimers.removeValue(forKey: name)
        }
    }
}

