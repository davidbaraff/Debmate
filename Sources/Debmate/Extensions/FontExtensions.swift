//
//  UIFontExtensions.swift
//  Debmate
//
//  Copyright © 2018 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import CoreGraphics

public typealias PlatformFont = UIFont

public extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    #if os(tvOS)
    static let systemFontSize = CGFloat(20)
    #endif
    
    static var standardSystemFont: UIFont {
        UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }

    var italic : UIFont {
        return withTraits(.traitItalic)
    }

    var bold : UIFont {
        return withTraits(.traitBold)
    }
    
    var boldItalic : UIFont {
        return withTraits(.traitBold, .traitItalic)
    }
    
    /// Apply an affine transform to the 100 pointsize version
    /// of self so that the font rescales to pointSize.
    func standardlyScaled(to pointSize: Double) -> UIFont {
        let scale = CGFloat(pointSize / 100.0)
        let mtx = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: 0, ty: 0)
        let descriptor = self.fontDescriptor.withSize(100.0).withMatrix(mtx)
        return UIFont(descriptor: descriptor, size: 0.0)
    }
}

#endif

#if os(macOS)

import AppKit

public typealias PlatformFont = NSFont

public extension NSFont {
    static var standardSystemFont: NSFont {
        NSFont.systemFont(ofSize: 0)
    }

    var italic: NSFont {
        NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask)
    }

    var bold: NSFont {
        NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask)
    }

    var boldItalic: NSFont {
        self.bold.italic
    }

    /// Apply an affine transform to the 100 pointsize version
    /// of self so that the font rescales to pointSize.
    func standardlyScaled(to pointSize: Double) -> NSFont {
        if let familyName = self.familyName,
           familyName.lowercased().contains("emoji") {
            return NSFont(descriptor: self.fontDescriptor, size: CGFloat(pointSize))!
        }

        let scale = CGFloat(pointSize / 100.0)
        let mtx = AffineTransform(m11: scale, m12: 0, m21: 0, m22: scale, tX: 0, tY: 0)
        guard let newFont = NSFont(descriptor: self.fontDescriptor.withSize(100.0), textTransform: mtx) else {
            fatalErrorForCrashReport("failed to scale font \(self) to size \(pointSize)")
        }
        return newFont
    }
}

#endif

