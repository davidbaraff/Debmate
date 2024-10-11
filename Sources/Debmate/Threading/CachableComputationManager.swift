//
//  CachableResult.swift
//  Debmate
//
//  Copyright © 2017 David Baraff. All rights reserved.
//

import Foundation

fileprivate struct Queue<T> {
    var array = [T?]()
    var head = 0
    
    var isEmpty: Bool {
        return head == array.count
    }
    
    mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    mutating func dequeue() -> T? {
        guard head < array.count,
            let element = array[head] else {
                return nil
        }
        
        array[head] = nil
        head += 1
        
        if array.count > 50 && Double(head) / Double(array.count) > 0.25 {
            array.removeFirst(head)
            head = 0
        }
        
        return element
    }
}

// MARK: -
private protocol CachableComputation {
    func run() -> Bool
    var description: String { get }
}

// MARK: -
private final class Computation<T : Sendable> : CachableComputation, Sendable {
    let work: @Sendable () -> (T?, Bool)
    let completionHandler: @Sendable (T, String) -> Void
    let key: String
    let cacheFile: URL
    let cutoffDate: Date?
    
    var description:String {
        return key
    }
    
    init(key:String,
         cacheFile: URL,
         work: @escaping (@Sendable () -> (T?, Bool)),
         cutoffDate: Date?,
         completionHandler: @escaping (@Sendable (T, String) -> Void)) {
        self.key = key
        self.cacheFile = cacheFile
        self.work = work
        self.completionHandler = completionHandler
        self.cutoffDate = cutoffDate
    }

    func run() -> Bool {
        // Check the cache first.
        if FileManager.default.fileExists(atPath: cacheFile.path) {
            
            if let data = try? Data(contentsOf: cacheFile),
               let cachableAny = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSData.self, from: data),
                let result: T = decodeFromCachableAny(cachableAny) {
                DispatchQueue.main.async {
                    self.completionHandler(result, self.key)
                }
                
                // if the file is old, keep going and redo the computation
                guard let cutoffDate = cutoffDate else {
                    return true
                }
                
                if let fileDate = (try? FileManager.default.attributesOfItem(atPath: cacheFile.path)[.creationDate]) as? Date,
                    fileDate > cutoffDate {
                    return true
                }
            }
        }

        let (result, completed) = work()
        if let result = result {
            DispatchQueue.main.async {
                self.completionHandler(result, self.key)
            }
            
            let any = encodeAsCachableAny(result)
            if Debmate.Util.ensureDirectoryExists(url: cacheFile.deletingLastPathComponent()) {
                try? NSKeyedArchiver.archivedData(withRootObject: any, requiringSecureCoding: true).write(to: cacheFile)
            }
            
            return true
        }
        
        // Return false to indicate we want to retry
        return completed
    }
}

// MARK: -

/// Class for managing computations that are designed to be cached for future reuse.
///

public final class CachableComputationManager : @unchecked Sendable {
    private let lock:DispatchQueue
    
    private var pendingComputations = Queue<CachableComputation>()
    private var pendingFailedComputations = [CachableComputation]()
    private var semaphore = DispatchSemaphore(value: 0)
    private var shutdown = false
    private var keepAlive:CachableComputationManager?
    private var keys = Set<String>()
    static private let workQueue = DispatchQueue(label: "com.debmate.cachableComputationManager" , qos: .utility,
                                                 attributes: [.concurrent])
    
    /// Create a new manager.
    ///
    /// - Parameter name: name is used only for debugging purposes
    public init(name: String) {
        let qname = "com.debmate.cachable-computation-manager.\(name)"
        lock = DispatchQueue(label: "\(qname)-lock")
        keepAlive = self

        CachableComputationManager.workQueue.async { [unowned self] in
            self.processPendingWork()
            self.keepAlive = nil
        }
    }

    /// Halt computations.
    ///
    /// A CachableComputationManager cannot be destroyed while it's worker
    /// queue/thread is active. Call halt() to shutdown the worker thread,
    /// which will then allow the manager to be deallocated if/when its
    /// reference count reaches zero.
    public func halt() {
        lock.sync {
            shutdown = true
            semaphore.signal()
        }
    }
    
    
    /// Add a computation to the manager.
    ///
    /// - Parameters:
    ///   - key: Key used to identify this computation
    ///   - cacheFile: URL for where the result should be cached
    ///   - work: The work function
    ///   - completionHandler: Notification that the computation has (succesfully) finished.
    ///
    /// The work function returns a result a tuple of type (T?, Bool); if the T? value is non-nil,
    /// it indicates the computation has finished (and will not be rerun).
    ///
    /// Note: The work function is always run in a non-main thread.
    ///
    /// In the case when the returned T? result is nil, the  Bool parameter is true to indicate the computation
    /// is considered complete and should not be retried; otherwise, a false value indicates the computation
    /// failed so it should be recomputed.  Failed computations are not rerun until retryFailedComputations
    /// is called.
    ///
    /// However, if the result can be read back from cacheFile then the cached value
    /// is considered the result of the computation.  A failed decode step is never retried.
    ///
    /// If an actual result is computed (either from the cache or the computation), it is handed to the
    /// completion handler, along with the key passed in.  The completion handler is always run on the main
    /// GUI thread.
    public func add<T : Sendable>(key: String,
                    cacheFile: URL,
                    work: @escaping (@Sendable () -> (T?, Bool)),
                    ignoringFilesOlderThan date: Date? = nil,
                    completionHandler: @escaping (@Sendable (T, String) -> Void)) {
        keys.insert(key)
        lock.sync {
            pendingComputations.enqueue(Computation(key: key, cacheFile: cacheFile,
                                                    work: work,
                                                    cutoffDate: date,
                                                    completionHandler:completionHandler))
            semaphore.signal()
        }
    }
    
    
    /// Check if a task with a particular key has been added.
    ///
    /// - Parameter key: key for task
    /// - Returns: true if add() was called with key
    public func contains(key: String) -> Bool {
        return keys.contains(key)
    }
    
    /// Retry any failed computations.
    ///
    /// - Returns: number of computations rescheduled.
    @discardableResult
    public func retryFailedComputations() -> Int {
        return lock.sync {
            let n = pendingFailedComputations.count
            for computation in pendingFailedComputations {
                pendingComputations.enqueue(computation)
                semaphore.signal()
            }

            pendingFailedComputations = []
            return n
        }
    }
    
    func processPendingWork() {
        var exitRequested = false
        while !exitRequested {
            semaphore.wait()
            
            let computation:CachableComputation? = lock.sync {
                if shutdown {
                    exitRequested = true
                    return nil
                }
                
                return pendingComputations.dequeue()
            }
            
            if let computation = computation {
                if !computation.run() {
                    lock.sync {
                        debugPrint("Retrying for failed computation \(computation.description)")
                        pendingFailedComputations.append(computation)
                    }
                }
            }
        }
    }
}
