//
//  UIScreenExtensions.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

#if os(iOS)

import UIKit

public extension UIScreen {
    var displayCornerRadius: CGFloat {
        if let radius = UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat {
            return radius + 2
        }
        return 0
    }
    
    var roundedDisplayCorners: Bool {
        return displayCornerRadius > 2
    }
}

#endif

