//
//  Timer.swift
//  Debmate
//
//  Copyright © 2017 David Baraff. All rights reserved.
//

import Foundation


/// A basic timer.
public class Timer {
    private var timer: DispatchSourceTimer?
    private let timeoutHandler: () -> ()
    private let queue: DispatchQueue
    
    /// The supplied handler is called whenever the timer fires.
    ///
    /// - Parameter handler: callback handler
    ///
    /// Note: the handler is always invoked on the main queue.
    public init(_ handler: @escaping () -> ()) {
        timeoutHandler = handler
        queue = DispatchQueue.main
    }

    /// The supplied handler is called whenever the timer fires.
    ///
    /// - Parameter queue: queue to execute handler on.
    /// - Parameter handler: callback handler
    ///
    /// Note: the handler is invoked on the passed in queue.
    public init(queue: DispatchQueue, _ handler: @escaping () -> ()) {
        timeoutHandler = handler
        self.queue = queue
    }

    
    /// Start the timer running repetitively.
    ///
    /// - Parameter interval: interval in seconds
    /// - Parameter callNow: if true,the timer immediately fires (otherwise the first call is in interval seconds)
    /// The timer will begin to fire every interval seconds until stop() is called.
    public func start(repeating interval: Double, callNow: Bool = false) {
        stop()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.setEventHandler(handler: timeoutHandler)
        t.schedule(deadline: .now() + (callNow ? 0 : interval), repeating: interval)
        t.resume()
        timer = t
    }
    
    /// Start the timer running in single-shot mode.
    ///
    /// - Parameter once: the timer is fired once, after the specified delay (in seconds).
    public func start(once delay: Double) {
        stop()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.setEventHandler(handler: timeoutHandler)
        t.schedule(deadline: .now() + delay)
        t.resume()
        timer = t
    }
    
    
    /// Prevents a timer from firing any more.
    ///
    /// This function is safe to call even if the timer isn't scheduled to fire.
    public func stop() {
        timer?.cancel()
        timer = nil
    }
}
