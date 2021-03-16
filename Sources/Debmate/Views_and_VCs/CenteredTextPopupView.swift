//
//  CenteredTextPopupView.swift
//  Debmate
//
//  Created by David Baraff on 11/27/17.
//  Copyright © 2017 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit

public class CenteredTextPopupView : UIView {
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label = UILabel()
        
        self.frame = CGRect(x: 0, y: 0, width: 300, height: 120)
        layer.cornerRadius = 12
        backgroundColor = UIColor(white: 0.30, alpha: 0.80)

        label.frame = self.frame
        label.font = .boldSystemFont(ofSize: 19)
        label.textAlignment = .center
        label.textColor = .white
        
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    /// Show a text popup over a view controller.
    ///
    /// - Parameters:
    ///   - message: message
    ///   - over: view controller to center popup over (defaults to root view controller)
    ///   - backgroundColor: optional background color (default is dark grey)
    ///   - duration: default duration for popover display (ignoring animations)
    ///   - completionHandler: optional completion handler
    ///
    /// If no view controller is supplied, the current root view controller is used.
    static public func show(_ message: String,
                            over viewController:UIViewController? = nil,
                            backgroundColor: UIColor? = nil,
                            duration: Double = 3.0,
                            completionHandler: (() -> ())? = nil) {
        let popupView = CenteredTextPopupView()
        let vc = viewController ?? Debmate.Util.rootViewController()
        
        popupView.label.text = message
        popupView.label.lineBreakMode = .byWordWrapping
        popupView.label.numberOfLines = 3
        if let backgroundColor = backgroundColor {
            popupView.backgroundColor = backgroundColor
        }
        
        func fadeAndRemove() {
            UIView.animate(withDuration: 0.5, delay: duration,
                           animations: { popupView.alpha = 0.00 }) {
                            _ in
                            popupView.removeFromSuperview()
                            if let completionHandler = completionHandler {
                                completionHandler()
                            }
            }
        }
        
        popupView.center = vc.view.center
        popupView.alpha = 0.0
        vc.view.addSubview(popupView)
        
        UIView.animate(withDuration: 0.5,
                       animations: { popupView.alpha = 1.0 }) { _ in
                        fadeAndRemove()
        }
    }
}

#endif

