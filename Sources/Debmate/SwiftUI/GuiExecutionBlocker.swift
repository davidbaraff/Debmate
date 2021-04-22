//
//  GUIExecutionBlocker.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Combine
import Foundation


/// Helper to disable user activity until a potentially long running
/// computation has finished.  However, if the computation is short enough
/// this class gives the illusion of non-blocking activity by waiting
/// to display an indication that the GUI is blocked until some short deadline
/// has passed.
///
/// Typical use:
///
///      func modifyModelState() {
///           guiExecutionBlocker.begin {
///              state.mutate()
///           } completion : {
///              dismiss()
///           }
///
/// Somewhere else in the UI, a notice of computation appears,
/// and user activity is disabled, as guiExecutionBlocker.visible and
/// guiExecutionBlocker.active become true, respectively.
public class GUIExecutionBlocker : ObservableObject {
    /// True if the work computation is running
    @Published public var active = false
    
    /// True if the UI should display some king of blocking indicator.
    @Published public var visible = false
    public private(set) var message: String?
    
    /// True if the UI must not interfere with a possibly IP drag
    @Published public var allowDragging = false
    
    let queue: DispatchQueue
    var requestID = 0
    
    struct State<T> {
        let startTime = Date()
        let showAfter: Double
        let minimumDisplayTime: Double
        let requestID: Int
        let completion: (T) -> ()
    }
    
    /// Returns an initialized instance of GUIExecutionBlocker.
    /// - Parameter queue: default queue for calls to begin().
    public init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    /// Begin computation
    /// - Parameters:
    ///   - message: optional display message for operation
    ///   - queue: queue for computation to be performed on (if nil
    ///            the queue passed to init is used)
    ///   - showAfter: how long to wait to show blocking activity
    ///   - minimumDisplayTime: once shown, blocking activity indicator
    ///     persists for at least this long, to avoid annoying fast UI flickers
    ///   - allowDragging: don't break the GUI by halting an IP drag operation
    ///   - work: work to be performed off the main queue)
    ///   - completion: completion (run on the main queue) after work completes
    public func begin<T>(message: String? = nil,
                         queue: DispatchQueue? = nil,
                         showAfter: Double = 0.2,
                         minimumDisplayTime: Double = 0.5,
                         allowDragging: Bool = false,
                         work: @escaping () -> T,
                         completion: @escaping (T) -> ()) {
        requestID += 1
        active = true
        self.allowDragging = allowDragging
        self.message = message
        let state = State(showAfter: showAfter, minimumDisplayTime: minimumDisplayTime,
                          requestID: requestID, completion: completion)
        
        (queue ?? self.queue).async {
            DispatchQueue.main.asyncAfter(deadline: .now() + showAfter) {
                if state.requestID == self.requestID && self.active {
                    self.visible = true
                }
            }

            let result = work()
            DispatchQueue.main.async {
                self.end(state: state, result: result)
            }
        }
    }

    
    /// Request display of gui elements without providing a computation.
    /// - Parameters:
    ///   - message: optional display message for operation
    ///   - showAfter:  how long to wait to show blocking activity
    ///   - minimumDisplayTime: nce shown, blocking activity indicator
    ///     persists for at least this long, to avoid annoying fast UI flickers
    ///   - allowDragging: don't break the GUI by halting an IP drag operation
    /// - Returns: A closure which must be called to end the GUI blocking.
    public func manualBegin(message: String? = nil,
                            showAfter: Double = 0.2,
                            minimumDisplayTime: Double = 0.5,
                            allowDragging: Bool = false) -> (() -> ()) {
        requestID += 1
        active = true
        self.allowDragging = allowDragging
        self.message = message
        let state = State(showAfter: showAfter, minimumDisplayTime: minimumDisplayTime,
                          requestID: requestID, completion: { })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + showAfter) {
            if state.requestID == self.requestID && self.active {
                self.visible = true
            }
        }

        return {  self.end(state: state, result: ()) }
    }
    

    private func end<T>(state: State<T>, result: T) {
        guard state.requestID == requestID else {
            state.completion(result)
            return
        }
        
        if !visible {
            active = false
            allowDragging = true
            state.completion(result)
            return
        }

        let timeRemaining = state.minimumDisplayTime - Date().timeIntervalSince(state.startTime)
        if timeRemaining > 0 {
            visible = true
            DispatchQueue.main.asyncAfter(deadline:.now() + timeRemaining) {
                self.visible = false
                self.active = false
                self.allowDragging = true
                state.completion(result)
            }
        }
        else {
            visible = false
            active = false
            self.allowDragging = true
            state.completion(result)
        }
    }
}
