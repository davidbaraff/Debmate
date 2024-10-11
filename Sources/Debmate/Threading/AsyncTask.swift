//
//  AsyncTask.swift
//  Debmate
//
//  Copyright © 2017 David Baraff. All rights reserved.
//

import Foundation

internal protocol WorkItem : Sendable {
    func execute()
    func cancel()
    func addCancelationHandler(_ handler:@escaping () -> Void)
    var wasCanceled: Bool { get }
    var isFinished: Bool { get }
    var progressHandler: ((Float) -> Void)? { get }
    var progressTransformStack: [(Float, Float)] { get set }
}

/**
    - requires:
 `import Debmate`

 Run a computation on a non-main thread, delivering results
 back to the main thread, with cancelation.
 
 Each AsyncTask instance allows for a single task to be running
 on a non-main thread.  Explicitly canceling a working task, or
 adding a new task via execute() indicates that the work being
 done by the currently running task is to be discarded.
 
 Accordingly, a canceled task does not run its completion handler,
 but does run its cancelation handlers (if any).
 
 Note that the actual work function being run is never explicitly
 terminated; instead, the work function may, if it chooses, opt
 to short-circuit its work by affecting its state via the cancelation
 handlers.  For example, a cancelation handler might instruct an ongoing
 network connection to shutdown and return earlier.
 
 More directly, a computation can always check for cancelation by
 writing
 
     if AsyncTask.wasCanceled {
        // return early
     }
 
 This will return true only if the request is made from the specific
 non-main queue in which the work was actually launched.  Additionally,
 once started, a running task can add additional cancelation handlers
 (again, only from the non-main queue in which the task was actually
 launched) by writing, for example:
 
     let dataTask = urlSession.dataTask(with: someURL)
     AsyncTask.addCancelationHandler { dataTask.cancel() }
 
 In this case, the cancelation handler could not be added when the work
 was scheduled, but only after work had progressed.  If the AsyncTask.cancel()
 method is called for the above work, this results in the dataTask object
 receiving a cancel request.
*/
public class AsyncTask {
    private class Work<T> : WorkItem, @unchecked Sendable  {
        var throwingWorkClosure: (() throws -> T)? = nil
        var workClosure: (() -> T)? = nil
        var completionHandlerForThrowing: ((T?, Error?) -> Void)? = nil
        var completionHandler: ((T) -> Void)? = nil
        
        var cancelationHandlers = [() -> Void]()

        var canceled = false
        var completed = false
        let workQueue: DispatchQueue
        let lock: DispatchQueue
        var currentProgressHandler: ((Float) -> Void)?
        var progressTransformStack = [(Float(0), Float(1))]
        
        init (_ name:String,
              _ work: @escaping () throws -> T,
              _ cancelationHandler: (() -> Void)?,
              _ completionHandler: @escaping (T?, Error?) -> Void,
              _ progressHandler: (@Sendable (Float) -> Void)?,
              _ qos: DispatchQoS) {
            workQueue = DispatchQueue(label: name, qos: qos)
            lock = DispatchQueue(label: "\(name)-lock")
            installProgressHandler(progressHandler)

            self.throwingWorkClosure = work
            self.completionHandlerForThrowing = completionHandler

            if let ch = cancelationHandler {
                cancelationHandlers.append(ch)
            }
        }
        
        init (_ name: String,
              _ work: @escaping () -> T,
              _ cancelationHandler: (() -> Void)?,
              _ completionHandler: @escaping (T) -> Void,
              _ progressHandler: (@Sendable (Float) -> Void)?,
              _ qos: DispatchQoS) {
            workQueue = DispatchQueue(label: name, qos: qos)
            lock = DispatchQueue(label: "\(name)-lock")
            installProgressHandler(progressHandler)

            self.workClosure = work
            self.completionHandler = completionHandler

            if let ch = cancelationHandler {
                cancelationHandlers.append(ch)
            }
        }
        
        private func installProgressHandler(_ progressHandler: (@MainActor (Float) -> Void)?) {
            if let progressHandler = progressHandler {
                currentProgressHandler = { value in
                    let (base, delta) = self.progressTransformStack.last ?? (0, 1)
                    let transformedValue = base + delta * value
                    DispatchQueue.main.async {
                        progressHandler(transformedValue)
                    }
                }
            }
        }
            
        var wasCanceled: Bool {
            // this is an inherently racy query, so no point
            // protecting it with a lock
            return canceled
        }
        
        var isFinished: Bool {
            // this is an inherently racy query, so no point
            // protecting it with a lock
            return canceled || completed
        }
        
        var progressHandler: ((Float) ->Void)? {
            return currentProgressHandler
        }
        
        func cancel() {
            let runCancelation: Bool = lock.sync {
                if !canceled && !completed {
                    canceled = true
                    return true
                }
                return false
            }
            
            if runCancelation {
                DispatchQueue.main.async {
                    for handler in self.cancelationHandlers {
                        handler()
                    }
                }
            }
        }
    
        func addCancelationHandler(_ handler: @escaping () -> Void) {
            lock.sync {
                if !canceled && !completed {
                    cancelationHandlers.append(handler)
                }
            }
        }
        
        func execute() {
            workQueue.setSpecific(key: AsyncTask.currentWorkKey, value: self)
            workQueue.async {
                self.executeInternal()
            }
        }
        
        private func executeInternal() {
            var result:T? = nil
            var caughtError:Error? = nil
            var throwing = true
            
            if let throwingWorkClosure = throwingWorkClosure {
                do {
                    result = try throwingWorkClosure()
                } catch {
                    caughtError = error
                }
                self.throwingWorkClosure = nil
            }
            else {
                guard let workClosure = workClosure else {
                    fatalErrorForCrashReport("both workClosure and throwingWorkClosure are nil")
                }
                
                throwing = false
                result = workClosure()
                self.workClosure = nil
            }
            
            lock.sync {
                if !canceled {
                    completed = true
                }
                workQueue.setSpecific(key: AsyncTask.currentWorkKey, value: nil)
            }
            
            if throwing {
                if completed,
                    let ch = self.completionHandlerForThrowing {
                    DispatchQueue.main.async {
                        ch(result, caughtError)
                    }
                }
            }
            else {
                if completed,
                    let result = result,
                    let ch = self.completionHandler {
                    DispatchQueue.main.async {
                        ch(result)
                    }
                }
            }
            
            self.completionHandler = nil
            self.completionHandlerForThrowing = nil
        }
    }
    
    /// True if cancelation was requested for the currently running task.
    ///
    /// - Note: The value is True only if cancelation was requested and this
    /// variable is being examined in the same queue from which it was launched.
    static public var cancelationWasRequested: Bool {
        if let currentWork = DispatchQueue.getSpecific(key: currentWorkKey) {
            guard let currentWork = currentWork else {
                fatalErrorForCrashReport("currentWork value is nil in dispatch queue of task")
            }
            return currentWork.wasCanceled
        }
        return false
    }

    /// Retrieve a progress handler for the currently running task.
    ///
    /// - Note: This variable is nil if a progress handler was not set when
    /// this task was executed, or if this call is not being made from the queue
    /// in which the task is running.
    ///
    /// It is recommended that a task cache this variable, as it is not completely
    /// trivial to compute.  If non-nil, call the retrieved progress handler to report
    /// progress with a value between 0.0 and 1.0.
    static public var progressHandler: ((Float) -> Void)? {
        if let currentWork = DispatchQueue.getSpecific(key: currentWorkKey) {
            guard let currentWork = currentWork else {
                fatalErrorForCrashReport("currentWork value is nil in dispatch queue of task")
            }
            return currentWork.progressHandler
        }
        return nil
    }

    /// Sets the range for calls to progressHandler.
    ///
    /// - Note: This call has no effect if this call is not being made from the queue
    /// in which the task is running.
    ///
    /// Call this at the beginning of a section of work which constitutes working
    /// on the current "slice" from a value of startValue to endValue.  When this section
    /// of work is done, call popProgressSlice().
    ///
    /// Calls may nest, so that a given progressHandler can be called with a range of values
    /// between 0 and 1 to indicate work done on an arbitrary fraction.
    ///
    /// For example, without any calls to pushProgressSlice(), calling the progressHandler
    /// with a value of 0.25 indicates 25% of the work is done.
    ///
    /// However, if pushProgressSlice(0.6, 0.7) is called, then calling progressHandler(0.25)
    /// translates to being 0.6 + (0.3 - 0.2) * 0.25 = 62.5% done.
    
    /// Additional calls to pushProgressSlice() could refine this range even further.
    /// Each call to pushProgressSlice() should be balanced by a call to popProgressSlice().
    
    static public func pushProgressSlice(startValue: Float, endValue: Float) {
        if let currentWork = DispatchQueue.getSpecific(key: currentWorkKey) {
            guard var currentWork = currentWork else {
                fatalErrorForCrashReport("currentWork value is nil in dispatch queue of task")
            }
            let (base, delta) = currentWork.progressTransformStack.last ?? (0, 1)
            currentWork.progressTransformStack.append((base + delta * startValue, delta * (endValue - startValue)))
        }
    }
    
    /// Pop the "slice" from a previous call to pushProgressSlice().
    ///
    /// - Note: This call has no effect if this call is not being made from the queue
    /// in which the task is running.
    ///
    static public func popProgressSlice() {
        if let currentWork = DispatchQueue.getSpecific(key: currentWorkKey) {
            guard var currentWork = currentWork else {
                fatalErrorForCrashReport("currentWork value is nil in dispatch queue of task")
            }
            guard !currentWork.progressTransformStack.isEmpty else {
                fatalErrorForCrashReport("popProgressSlice tried to pop an empty stack")
            }
            currentWork.progressTransformStack.removeLast()
        }
    }

    /// Add a cancelation handler to a currently running task.
    ///
    /// Cancelation handlers are always run on the main thread.
    ///
    /// - Parameter handler: handle to be executed if the task is canceled.
    /// - Returns: True if a cancelation handle was actually added.
    /// - Note: This function has no effect unless called from the same
    ///   queue in which the task was launched.
    ///
    @discardableResult
    static public func addCancelationHandler(handler: @escaping () -> Void) -> Bool {
        if let currentWork = DispatchQueue.getSpecific(key: currentWorkKey) {
            guard let currentWork = currentWork else {
                fatalErrorForCrashReport("currentWork value is nil in dispatch queue of task")
            }
            currentWork.addCancelationHandler(handler)
            return true
        }
        return false
    }
    
    let name: String
    let qos: DispatchQoS
    var ctr = 0
    static let currentWorkKey = DispatchSpecificKey<WorkItem?>()
    var currentWork: WorkItem? = nil
    var pendingProgressHandler: (@Sendable (Float) -> Void)?
    
    /// Create a new container for running tasks.
    ///
    /// - Parameter name: The name is used for debugging purposes only.
    /// - Parameter qos: Quality of service.
    public init(_ name: String, qos: DispatchQoS = .utility) {
        self.name = name
        self.qos = qos
    }
    
    /// True if a task is currently running.
    public var isRunning: Bool {
        return !(currentWork?.isFinished ?? true)
    }

    /// Cancel a running task.
    ///
    /// - Returns: True if there was a running task to be canceled.
    /// - Note: This function should only be called from the main thread.
    @discardableResult
    public func cancel() -> Bool {
        if let work = currentWork {
            work.cancel()
            currentWork = nil
            return true
        }
        return false
    }

    
    /// Set a progress handler.
    ///
    /// - Parameter progressHandler: closure taking a single Float
    ///
    /// - Warning: This call sets a progress handler that only takes effect
    ///   for the next task invoked by a call to execute().  The progress handler
    ///   set remains set for all subsequent calls to execute().
    ///
    /// To report progress, a running task can retrieve a progress handler via
    /// a call to AsyncTask.progressHandler.  The task can then periodically pass
    /// a value between 0.0 and 1.0 to the handler to indicate progress. 

    public func setProgressHandler(_ progressHandler: @escaping @Sendable (Float) -> Void) {
        self.pendingProgressHandler = progressHandler
    }
    
    /// Run work in a non-main queue, handling thrown exceptions.
    ///
    /// The completion handler is called with an optional result of type T
    /// and an optional error.  The error indicates that the work closure
    /// threw some sort of an error; in this case, the result parameter will
    /// be nil.  Otherwise, if error is nil then the result parameter is guaranteed
    /// to be non-nil.  However, if the task is canceled, the completion handler
    /// is not called but all cancelation handlers for the task are run instead.
    ///
    /// If a task was already running, the already running task is canceled.
    ///
    /// Note that additional cancelation handlers can be added after the task
    /// is launched, from within the queue that the work is running, via a
    /// call to AsyncTask.addCancelationHandler().
    ///
    /// Both cancelation and completion handlers are always run in the main thread.
    ///
    /// - Parameters:
    ///   - work: Work to be done.
    ///   - cancelationHandler: An optional callback if the work is canceled.
    ///   - completionHandler: Called only if the task is not canceled.
    ///   - Returns: True if a previously running task was canceled.
    ///
    @discardableResult
    public func execute<T>(_ work: @escaping () throws -> T, cancelationHandler:(() -> Void)? = nil,
                        completionHandler: @escaping (T?, Error?) -> Void) -> Bool {
        let canceled = cancel()
        ctr += 1
        let work = Work<T>("\(name)-\(ctr)", work, cancelationHandler, completionHandler,
                           pendingProgressHandler, qos)
        currentWork = work
        work.execute()
        return canceled
    }

    /// Run work in a non-main queue.
    ///
    /// The completion handler is called with the result of type T returned by
    //// the work closure,  unless the task is canceled.
    ///
    /// If a task was already running, the already running task is canceled.
    ///
    /// Note that additional cancelation handlers can be added after the task
    /// is launched, from within the queue that the work is running, via a
    /// call to AsyncTask.addCancelationHandler().
    ///
    /// Both cancelation and completion handlers are always run in the main thread.
    ///
    /// - Parameters:
    ///   - work: Work to be done.
    ///   - cancelationHandler: An optional callback if the work is canceled.
    ///   - completionHandler: Called only if the task is not canceled.
    ///   - Returns: True if a previously running task was canceled.
    ///
    @discardableResult
    public func execute<T>(_ work: @escaping () -> T, cancelationHandler: (() -> Void)? = nil,
                        completionHandler: @escaping (T) -> Void) -> Bool {
        let canceled = cancel()
        ctr += 1
        let work = Work<T>("\(name)-\(ctr)", work, cancelationHandler, completionHandler,
                           pendingProgressHandler, qos)
        currentWork = work
        work.execute()
        return canceled
    }
}
