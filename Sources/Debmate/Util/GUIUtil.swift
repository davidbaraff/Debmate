//
//  GUIUtil.swift
//  Debmate
//
//  Created by David Baraff on 3/13/19.
//  Copyright © 2019 deb. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

extension Util {
    /// Show an (asynchronous) modal warning dialog.
    ///
    /// - Parameters:
    ///   - title: title for warning
    ///   - details: message body (optional)
    ///   - over: view controller (defaults to root view controller)
    ///   - transparent: allow slight transparency (not good for dark background)
    ///   - centered: center the detail text; otherwise, left justified.
    ///   - completionHandler: completion handler
    ///
    static public func showWarning(_ title: String, details: String? = nil,
                                   over viewController: UIViewController,
                                   transparent: Bool = false,
                                   centered: Bool = true,
                                   completionHandler: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        if let details = details {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = centered ? .center : .left
            
            let messageText = NSMutableAttributedString(string: details,
                                                        attributes: [
                                                            NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .footnote),
                                                            NSAttributedString.Key.paragraphStyle: paragraphStyle])
            ac.setValue(messageText, forKey: "attributedMessage")
        }
        
        
        if !transparent {
            ac.view.backgroundColor = UIColor.white
            ac.view.layer.cornerRadius = 12
        }
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
        
        ac.addAction(okAction)
        viewController.present(ac, animated: true)
    }
    
    /// Show a modal confirmation dialog.
    ///
    /// - Parameters:
    ///   - title: title for warning
    ///   - action: action being taken (e.g. "Upload", "Remove")
    ///   - details: message body (optional)
    ///   - autoConfirmWhen: if true, skip dialog and and call completion handler with true
    ///   - over: view controller (defaults to root view controller)
    ///   - transparent: allow slight transparency (not good for dark background)
    ///   - completionHandler: completion handler (called with true or false)
    static public func confirmAction(_ title: String, action:String,
                                     details: String? = nil,
                                     autoConfirmWhen: Bool = false,
                                     over viewController: UIViewController,
                                     transparent: Bool = false,
                                     cancelString: String = "Cancel",
                                     completionHandler: ((Bool) -> Void)? = nil) {
        if autoConfirmWhen {
            completionHandler?(true)
            return
        }
        
        let ac = UIAlertController(title: title, message:details, preferredStyle: .alert)
        
        if !transparent {
            ac.view.backgroundColor = UIColor.white
            ac.view.layer.cornerRadius = 12
        }
        
        let confirmAction = UIAlertAction(title: action, style: .default) { _ in
            completionHandler?(true)
        }
        
        let cancelAction = UIAlertAction(title: cancelString, style: .cancel) { _ in
            completionHandler?(false)
        }
        
        ac.addAction(cancelAction)
        ac.addAction(confirmAction)
        viewController.present(ac, animated: true)
    }
}

public class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    public var completion: (() -> Void)?
    
    override public func perform() {
        super.perform()
        if let completion = completion {
            completion()
        }
    }
}

#endif

