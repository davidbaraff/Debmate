//
//  UIFontExtensions.swift
//  Debmate
//
//  Copyright © 2018 David Baraff. All rights reserved.
//

#if os(iOS)

import UIKit

extension UIFont {
    public func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: 0) //size 0 means keep the size as it is
        }
        else {
            return self
        }
    }
    
    public func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    public func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}

#endif

