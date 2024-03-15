//
//  StringExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
#if !os(Linux)
import SwiftUI
#endif

public extension String {
    /// Safely convert string to data via its underlying utf8-view
    var asData: Data {
        Data(self.utf8)
    }

    /// Return the md5 checksum of a string
    var md5Digest: String {
        Util.md5Digest(self)
    }

    /// Return an NSRange that full encompasses the string
    var fullRange: NSRange {
        NSRange(location: 0, length: count)
    }

    /// Return a range of the string.
    func substring(withRange range: NSRange) -> String {
        if let swiftRange = Range(range, in: self) {
            return String(self[swiftRange])
        }
        return ""
    }
    
    /// Return the string with leading and trailing whitespace trimmed off.
    var trimmed: String {
        self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Return the string with leading whitespace trimmed off.
    var leadingTrimmed: String {
        self.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }
    
    /// Return an ascii-safe version of self
    var asciiSafe: String {
        String(self.unicodeScalars.filter { $0.value >= 32 && $0.value <= 126 })
    }
    
    /// Returns a utf8 contiguous version of a string
    var utf8Contiguous: String {
        var s = self
        s.makeContiguousUTF8()
        return s
    }
    
    /// String without path extension.
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
    
    #if !os(Linux) && !os(watchOS)
    func attributedString(withFont font: PlatformFont, color: CGColor? = nil,
                          underLine: Bool = false,
                          alignment: NSTextAlignment? = nil) -> NSAttributedString {
        var attrs: [NSAttributedString.Key : Any] = [.font : font]
        #if os(macOS)
        if let color = color,
           let nsColor = NSColor(cgColor: color) {
            attrs[.foregroundColor] = nsColor
        }
        #else
        if let color = color {
            attrs[.foregroundColor] = UIColor(cgColor: color)
        }
        #endif

        if underLine {
            attrs[.underlineStyle] = 1
            attrs[.expansion] = -0.001
        }

        if let alignment = alignment {
            let ps = NSMutableParagraphStyle()
            ps.setParagraphStyle(.default)
            ps.alignment = alignment
            attrs[.paragraphStyle] = ps
        }

        let ma = NSMutableAttributedString(string: self)
        ma.setAttributes(attrs, range: ma.fullRange)
        return ma
    }
    #endif
}

#if !os(Linux)
public extension NSAttributedString {
    var fullRange: NSRange {
        NSRange(location: 0, length: length)
    }
}
#endif

