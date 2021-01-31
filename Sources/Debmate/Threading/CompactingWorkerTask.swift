//
//  CompactingWorkerTask.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//


import Foundation


/// Schedule a sequence of tasks to be run asychronously, with compacted scheduling.
class CompactingWorkerTask {
    let workQueue: DispatchQueue
    let lock = DispatchQueue(label: "com.debmate.compactingworkertask.lock")

    var running = false
    var scheduledWork: (() -> ())?
    
    /// Construct a new compacting worker task
    /// - Parameters:
    ///   - workQueue: The queue to run work on (defaults to DispatchQueue.global()).
    ///
    /// Note: To actually do anything you must call submitWork.
    public init(workQueue: DispatchQueue? = nil) {
        self.workQueue = workQueue ?? DispatchQueue.global()
    }

    
    /// Schedule work to be done.
    /// - Parameter work: A function to be run.
    ///
    /// The function work is scheduled to be run as soon as the current task is finished.
    /// However, if submitWork() is called again before the work scheduled has even begin,
    /// the new work scheduled preempts the old work, and the scheduled, but never begun
    /// task is "compacted" away.
    public func submitWork(work: @escaping () -> ()) {
        lock.sync {
            if !running {
                running = true
                scheduledWork = work
                workQueue.async {
                    self.worker()
                }
            }
            else {
                scheduledWork = work
            }
        }
    }
    
    private func worker() {
        while true {
            let work: (() ->())? = lock.sync {
                if scheduledWork == nil {
                    running = false
                    return nil
                }
                else {
                    let old = scheduledWork
                    scheduledWork = nil
                    return old
                }
            }
            
            if let work = work {
                work()
            }
            else {
                return
            }
        }
    }
}
