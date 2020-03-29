//
//  AsyncTask+GUI.swift
// Debmate
//
//  Copyright © 2017 David Baraff. All rights reserved.
//

#if os(iOS)

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

extension AsyncTask {
    static public func run<T>(_ work: @escaping (() -> T),
                           withCancelationMessage msg: String,
                           showAfter: Double = 0.5,
                           cancelAfter: Double? = 3.0,
                           over viewController: UIViewController? = nil,
                           cancelationHandler: (() ->Void)? = nil,
                           completionHandler: ((T) ->Void)? = nil) {
        let op = CancelableGUIOperation(msg, showAfter, cancelAfter)
        op.execute(work, viewController, cancelationHandler, completionHandler)
    }
    
    static public func run<T>(_ work: @escaping (() throws -> T),
                           withCancelationMessage msg:String,
                           showAfter: Double = 0.5,
                           cancelAfter: Double? = 3.0,
                           over viewController: UIViewController? = nil,
                           cancelationHandler: (() ->Void)? = nil,
                           completionHandler: ((T?, Error?) ->Void)? = nil) {
        let op = CancelableGUIOperation(msg, showAfter, cancelAfter)
        op.execute(work, viewController, cancelationHandler, completionHandler)
    }
}

#endif

