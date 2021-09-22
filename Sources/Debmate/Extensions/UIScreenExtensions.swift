//
//  UIScreenExtensions.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

#if os(iOS)

import UIKit

public extension UIScreen {
    /// The corner radius (if any) for this particular display.
    var displayCornerRadius: CGFloat {
        if let radius = UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat {
            return radius + 2
        }
        return 0
    }
    
    /// True if this particular display has rounded corners.
    var roundedDisplayCorners: Bool {
        return displayCornerRadius > 2
    }
}

#endif

