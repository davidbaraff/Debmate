//
//  RefreshHelper.swift
//  Debmate
//
//  Created by David Baraff on 7/25/19.
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

/// Coalesce refresh updates for a GUI.
///
/// Use this class to quickly mark some bit of UI in need of updating;
/// when the next event-loop kicks over, the refresh function is called.
/// For example:
///
/// class MyWindow {
///    let refreshHelper: RefreshHelper
///
///    init() {
///        refreshHelper = RefreshHelper { [weak self] in self?._resortItems() }
///    }
///
///    func itemChanged(...) {
///         // don't do anything right now
///         refreshHelper.updateNeeded()
///    }
///
///  func _resortItems() {
///         // <actually do the work of resorting items
///  }
///
public class RefreshHelper {
    private let updateHandler: () -> ()
    private let queue: DispatchQueue
    private var updateScheduled = false
    private var lastUpdate = TimeInterval(0)
    
    /// The supplied handler is called when an update actually occurs.
    ///
    /// - Parameter queue: queue to execute handler on (defaults to Dispatch.main)
    /// - Parameter handler: callback handler
    ///
    /// Note: the handler is invoked on the passed in queue.
    public init(queue: DispatchQueue = .main, _ handler: @escaping () -> ()) {
        updateHandler = handler
        self.queue = queue
    }
    
    
    /// Schedule a call to the update handler
    ///
    /// - Parameter maxDelay: optional maximum delay till next call.
    ///
    /// If coalesceInterval is not specified, then a call to the update handler
    /// is scheduled for as soon as possible.  Otherwise, a call to the
    /// update handler is scheduled so that it occurs as soon as possible,
    /// with the constraint that the update handler will be called no sooner than
    /// coalesceInterval seconds after the most recent call to the update handler.
    ///
    /// Note: if the update handler has never fired, or has not fired for more
    /// than coalesceInterval seconds, it will be called as soon as possible.
    ///
    /// This function should only be called from the queue that the
    /// update handler will be invoked on.
    public func updateNeeded(coalesceInterval: Double? = nil) {
        guard !updateScheduled else { return }
        
        if let interval = coalesceInterval {
            let now = Date().timeIntervalSince1970
            let delay = interval - (now - lastUpdate)
            if delay <= 0 {
                updateScheduled = false
                lastUpdate = now
                updateHandler()
            }
            else {
                updateScheduled = true
                queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.updateScheduled = false
                    self?.lastUpdate = Date().timeIntervalSince1970
                    self?.updateHandler()
                }
            }
        }
        else {
            updateScheduled = true
            queue.async { [weak self] in
                self?.updateScheduled = false
                self?.lastUpdate = Date().timeIntervalSince1970
                self?.updateHandler()
            }
        }
    }
}
