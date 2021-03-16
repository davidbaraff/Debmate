//
//  AsyncTask+SwiftUI.swift
//  
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// A SwiftUI View can watch the published fields of this object
/// and show/hide UI elements in response to the changes in the published variables
/// of this object.
public class GUIAsyncTaskWatcher : ObservableObject {
    /// True if the work computation is running.
    @Published public var active = false
    
    /// True if the UI should display some king of blocking indicator.
    @Published public var visible = false
    
    
    /// Message describing the ongoing computational task.
    @Published public private(set) var message: String?
    
    /// True if the UI should show a cancellation button.
    @Published public var showCancelButton = false

    /// Progress of current task (between 0.0 and 1.0).
    @Published public var progress: Float?
    
    /// Access to the underlying async task if necessary.
    public let asyncTask = AsyncTask("anonymous-GUIAsyncTaskWatcher")
    
    let queue: DispatchQueue
    var requestID = 0
    
    struct State {
        let startTime = Date()
        let showAfter: Double
        let showCancelAfter: Double?
        let minimumDisplayTime: Double
        let requestID: Int
        let asyncTask: AsyncTask
    }
    
    /// Returns an initialized instance of GUIAsyncTaskWatcher.
    /// - Parameter queue: default queue for calls to begin().
    public init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    /// Begin watching an AsyncTask instance
    /// - Parameters:
    ///   - message: optional display message for operation
    ///   - queue: queue for computation to be performed on (if nil
    ///            the queue passed to init is used).
    ///   - showAfter: how long to wait to show blocking activity
    ///   - showCancelAfter: how long to wait to show a cancellation button;
    ///     zero indicates immediately, while nil indicates never
    ///   - minimumDisplayTime: once shown, blocking activity indicator
    ///     persists for at least this long, to avoid annoying fast UI flickers
    ///   - work: Work to be done.
    ///   - cancelationHandler: An optional callback if the work is canceled.
    ///   - completionHandler: Called only if the task is not canceled.
    ///
    /// Both cancelation and completion handlers are always run in the main thread.
    /// If both are supplied, it is guaranteed that exactly one will be called.
    
    public func begin<T>(message: String? = nil,
                         queue: DispatchQueue? = nil,
                         showAfter: Double = 0.2,
                         showCancelAfter: Double?,
                         minimumDisplayTime: Double = 0.5,
                         work: @escaping () -> T,
                         cancelationHandler: (() -> Void)? = nil,
                         completionHandler: @escaping (T) -> Void) {
        requestID += 1
        active = true
        progress = nil

        self.message = message
        let state = State(showAfter: showAfter, showCancelAfter: showCancelAfter,
                          minimumDisplayTime: minimumDisplayTime,
                          requestID: requestID, asyncTask: asyncTask)
        
        if let showCancelAfter = showCancelAfter {
            if showCancelAfter <= 0 {
                showCancelButton = true
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() + showCancelAfter) {
                    if state.requestID == self.requestID && self.active {
                        self.showCancelButton = true
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + showAfter) {
            if state.requestID == self.requestID && self.active {
                self.visible = true
            }
        }
        
        asyncTask.setProgressHandler { progress in
            DispatchQueue.main.async {
                self.progress = progress
            }
        }

        asyncTask.execute(work) {
            self.end(state: state)
            cancelationHandler?()
        } completionHandler: { result in
            self.end(state: state)
            completionHandler(result)
        }
    }

    private func end(state: State) {
        guard state.requestID == requestID else {
            return
        }
        
        requestID += 1
        
        if !visible {
            active = false
            return
        }

        let timeRemaining = state.minimumDisplayTime - Date().timeIntervalSince(state.startTime)
        if timeRemaining > 0 {
            visible = true
            DispatchQueue.main.asyncAfter(deadline:.now() + timeRemaining) {
                self.visible = false
                self.active = false
                self.showCancelButton = false
            }
        }
        else {
            visible = false
            active = false
            showCancelButton = false
        }
    }
}

