//
//  StringExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation

public extension String {
    /// Return an NSRange that full encompasses the string
    var fullRange: NSRange {
        return NSRange(location: 0, length: count)
    }
    
    /// Return the string with leading and trailing whitespace trimmed off.
    var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Return the string with leading whitespace trimmed off.
    var leadingTrimmed: String {
        self.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }
    
    /// Return an ascii-safe version of self
    var asciiSafe: String {
        return String(self.unicodeScalars.filter { $0.value >= 32 && $0.value <= 126 })
    }
    
    /// Returns a utf8 contiguous version of a string
    var utf8Contiguous: String {
        var s = self
        s.makeContiguousUTF8()
        return s
    }
}
