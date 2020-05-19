//
//  WorkerPool.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//


import Foundation


/// Manage a pool of n workers all doing the same thing.
public class WorkerPool {
    let workQueue: DispatchQueue
    let lock = DispatchQueue(label: "com.debmate.workerpool.lock")

    let nworkers: Int
    var nrunning = 0
    let work: () -> ()

    
    /// Construct a new pool
    /// - Parameters:
    ///   - nworkers: How many workers should run.
    ///   - workQueue: The queue they should run on (defaults to DispatchQueue.global()).
    ///   - work: The task they should run.
    /// - Note: You must call ensureWorking() to actually start the workers working.
    public init(nworkers: Int, workQueue: DispatchQueue? = nil, work: @escaping () -> ()) {
        self.nworkers = nworkers
        self.workQueue = workQueue ?? DispatchQueue.global()
        self.work = work
    }

    
    /// Ensure that the workers are running.
    ///
    /// This call makes sure that all nworkers workers have started running.
    public func ensureWorking() {
        lock.sync {
            while nrunning < nworkers {
                print("Started worker (nrunning = \(nrunning) out of \(nworkers))")
                nrunning += 1
                workQueue.async {
                    self.work()
                    self.lock.sync {
                        self.nrunning -= 1
                        print("Ended worker (nrunning = \(self.nrunning) out of \(self.nworkers))")
                    }
                }
            }
        }
    }

    var upToDate = false
    var upToDateWorkerRunning = false
    
    public func ensureUpToDate() {
        lock.sync {
            upToDate = false
            if !upToDateWorkerRunning {
                upToDateWorkerRunning = true
                workQueue.async {
                    self.upToDateWorker()
                }
            }
        }
    }

    func upToDateWorker() {
        while true {
            print("Up to date worker has started")
            lock.sync {
                upToDate = true
            }
        
            work()

            let shouldExit: Bool = lock.sync {
                if upToDate {
                    print("Up to date worker has ended")
                    upToDateWorkerRunning = false
                    return true
                }
                else {
                    return false
                }
            }
            
            if shouldExit {
                return
            }
        }
    }
}

