//
//  AsyncTask+GUI.swift
//  Debmate
//
//  Copyright © 2017 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit

private class CancelableGUIOperation {
    let asyncTask = AsyncTask("anonymous-cancelable")
    let presentationDelay: Double
    let allowCancelationDelay: Double?
    let descr: String
    
    var cancelVC: CancelableTaskVC!
    var finished = false
    
    init(_ descr: String, _ presentationDelay: Double, _ allowCancelationDelay: Double?) {
        self.presentationDelay = presentationDelay
        self.allowCancelationDelay = allowCancelationDelay
        self.descr = descr
        
        asyncTask.setProgressHandler {
            self.cancelVC?.setProgress($0)
        }
    }
    
    @objc
    func cancelPressed() {
        finished = true
        asyncTask.cancel()
        cancelVC.dismiss(animated: true)
        cancelVC = nil
    }
    
    func execute<T>(_ work:@escaping () -> T,
                 _ presentingVC:UIViewController?,
                 _ cancelationHandler:(() -> Void)?,
                 _ completionHandler:((T) -> Void)?) {
        createAndPresent(vc: presentingVC ?? Debmate.Util.rootViewController())
        scheduleReveals()
        
        asyncTask.execute(work, cancelationHandler: cancelationHandler) { (result: T) in
            self.finished = true
            self.cancelVC.dismiss(animated: true) {
                if let ch = completionHandler {
                    ch(result)
                }
            }
        }
    }
    
    func execute<T>(_ work:@escaping () throws -> T,
                 _ presentingVC: UIViewController?,
                 _ cancelationHandler: (() -> Void)?,
                 _ completionHandler: ((T?, Error?) -> Void)?) {
        createAndPresent(vc: presentingVC ?? Debmate.Util.rootViewController())
        scheduleReveals()
        
        asyncTask.execute(work, cancelationHandler:cancelationHandler) { (result:T?, error:Error?) in
            self.finished = true
            self.cancelVC.dismiss(animated: true) {
                if let ch = completionHandler {
                    ch(result, error)
                }
            }
        }
    }
    
    func scheduleReveals() {
        DispatchQueue.main.asyncAfter(deadline: .now() + presentationDelay) {
            if !self.finished {
                self.cancelVC.popupView.isHidden = false
            }
        }
        
        if let allowCancelationDelay = allowCancelationDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + allowCancelationDelay) {
                if !self.finished {
                    self.cancelVC.cancelButton.isHidden = false
                }
            }
        }
    }
    
    func createAndPresent(vc:UIViewController) {
        cancelVC = CancelableTaskVC()
        
        // force the view to load now so we can set some properties
        _ = cancelVC.view
        
        cancelVC.cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cancelVC.modalPresentationStyle = .overFullScreen
        cancelVC.modalTransitionStyle = .crossDissolve
        cancelVC.label.text = descr
        cancelVC.cancelButton.isHidden = true
        cancelVC.popupView.isHidden = true
        vc.present(cancelVC, animated:false)
    }
}


/// Present a blocking modal dialog.
///
/// Usage:
///    let popup = CancelableModalPopup .run(...) { canceled in ... }
///
/// This presents a blocking dialog that is dismissed either by the user hitting
/// the cancel button, or by calling either popup.cancel() or popup.finish().
/// The completion handler passed to run is called with a bool argument that is true
/// if the user canceled or cancel() was called, and false otherwise.

public class CancelableModalPopup {
    let presentationDelay: Double
    let allowCancelationDelay: Double?
    let descr: String
    var completionHandler: ((Bool) -> ())?

    var cancelVC: CancelableTaskVC!
    var finished = false
    
    
    /// <#Description#>
    public func cancel() {
        dismiss(canceled: true)
    }
    
    public func finish() {
        dismiss(canceled: false)
    }

    /// Create and show a popup.
    /// - Parameters:
    ///   - msg: description of operation
    ///   - showAfter: show the popup after this much time
    ///   - cancelAfter: allow cancelation after this much time (or never)
    ///   - viewController: presenting view controller
    ///   - completionHandler: called when the popup is dismissed
    /// - Returns: A CancelationModalPopup instance.
    public init(withCancelationMessage msg: String,
                showAfter: Double = 0.5,
                cancelAfter: Double? = 3.0,
                over viewController: UIViewController,
                completionHandler: ((Bool) -> ())? = nil) {
        self.descr = msg
        self.presentationDelay = showAfter
        self.allowCancelationDelay = cancelAfter
        self.completionHandler = completionHandler
        createAndPresent(vc: viewController)
        scheduleReveals()
    }

    @objc
    func cancelPressed() {
        dismiss(canceled: true)
    }
    
    func dismiss(canceled: Bool) {
        guard !finished else {
            return
        }

        print("In cancel pressed, canceled is ", canceled)
        finished = true
        cancelVC.dismiss(animated: true) {
            self.completionHandler?(canceled)
        }
        cancelVC = nil
    }
    
    func scheduleReveals() {
        DispatchQueue.main.asyncAfter(deadline: .now() + presentationDelay) {
            if !self.finished {
                self.cancelVC.popupView.isHidden = false
            }
        }
        
        if let allowCancelationDelay = allowCancelationDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + allowCancelationDelay) {
                if !self.finished {
                    self.cancelVC.cancelButton.isHidden = false
                }
            }
        }
    }
    
    func createAndPresent(vc:UIViewController) {
        cancelVC = CancelableTaskVC()
        
        // force the view to load now so we can set some properties
        _ = cancelVC.view
        
        cancelVC.cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cancelVC.modalPresentationStyle = .overFullScreen
        cancelVC.modalTransitionStyle = .crossDissolve
        cancelVC.label.text = descr
        cancelVC.cancelButton.isHidden = true
        cancelVC.popupView.isHidden = true
        vc.present(cancelVC, animated:false)
    }
}


extension AsyncTask {
    @discardableResult
    static public func run<T>(_ work: @escaping (() -> T),
                           withCancelationMessage msg: String,
                           showAfter: Double = 0.5,
                           cancelAfter: Double? = 3.0,
                           over viewController: UIViewController? = nil,
                           completionHandler: ((T) ->Void)? = nil,
                           cancelationHandler: (() ->Void)? = nil) -> AsyncTask {
        let op = CancelableGUIOperation(msg, showAfter, cancelAfter)
        op.execute(work, viewController, cancelationHandler, completionHandler)
        return op.asyncTask
    }
    
    @discardableResult
    static public func run<T>(_ work: @escaping (() throws -> T),
                           withCancelationMessage msg:String,
                           showAfter: Double = 0.5,
                           cancelAfter: Double? = 3.0,
                           over viewController: UIViewController? = nil,
                           completionHandler: ((T?, Error?) ->Void)? = nil,
                           cancelationHandler: (() ->Void)? = nil) -> AsyncTask {
        let op = CancelableGUIOperation(msg, showAfter, cancelAfter)
        op.execute(work, viewController, cancelationHandler, completionHandler)
        return op.asyncTask
    }
}

#endif

