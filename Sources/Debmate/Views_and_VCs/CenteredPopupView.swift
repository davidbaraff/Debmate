//
//  CenteredPopupView.swift
//  Debmate
//
//  Created by David Baraff on 6/28/17.
//  Copyright © 2017 David Baraff. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

public class CenteredPopupView : UIView {
    var imageView: UIImageView!
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView = UIImageView()
        label = UILabel()
        
        self.frame = CGRect(x: 0, y: 0, width: 160, height: 160)
        layer.cornerRadius = 12
        backgroundColor = UIColor(white: 0.30, alpha: 0.80)
        
        imageView.frame = CGRect(x: 42, y: 29, width: 72, height: 72)
        label.frame = CGRect(x: 16, y: 109, width: 128, height: 41)
        label.font = .boldSystemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = .white
        
        addSubview(imageView)
        addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    /// Show a popup over a view controller.
    ///
    /// - Parameters:
    ///   - message: short message
    ///   - image: optional image
    ///   - over: view controller to center popup over (defaults to root view controller)
    ///   - tint: optional image tint
    ///   - backgroundColor: optional background color (default is dark grey)
    ///   - duration: default duration for popover display (ignoring animations)
    ///   - completionHandler: optional completion handler
    ///
    /// If no view controller is supplied, the current root view controller is used.
    static public func show(_ message: String,
                            image: UIImage? = nil,
                            over viewController: UIViewController? = nil,
                            tint: UIColor? = nil,
                            backgroundColor: UIColor? = nil,
                            duration: Double = 1.0,
                            completionHandler: (() -> ())? = nil) {
        let popupView = CenteredPopupView()
        
        if let image = image {
            popupView.imageView.image = image
            
            if let tint = tint {
                popupView.imageView.tintColor = tint
                popupView.imageView.image = image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        popupView.label.text = message
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
        
        let vc = viewController ?? Debmate.Util.rootViewController()
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

