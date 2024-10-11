//
//  StringUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
#if !os(Linux)
import CryptoKit
#else
import Crypto
#endif

#if os(iOS)
import UIKit
#endif

fileprivate let regex = try! NSRegularExpression(pattern: "([0-9]+)|([^0-9]+)")
fileprivate func splitIntoWords(_ s: String) -> [String] {
    let ns = s as NSString
    return regex.matches(in: s, range: NSRange(location: 0, length: s.count)).map {
        ns.substring(with: $0.range).lowercased()
    }
}

extension Util {
    // MARK: - String utilities
    
    /// Computes an md5 digest hash string.
    /// - Parameter s: Input string
    /// - Returns: md5 digest string (16 byte long hex string)
    public static func md5Digest(_ s: String) -> String {
        md5Digest(s.asData)
    }

    /// Computes an md5 digest hash string.
    /// - Parameter d: Input data
    /// - Returns: md5 digest string
    public static func md5Digest(_ data: Data) -> String {
        Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
    }

    /// Computes an SHA256 digest hash string.
    /// - Parameter s: Input string
    /// - Returns: SHA256 hex digest string
    public static func sha256Digest(_ s: String) -> String {
        sha256Digest(s.asData)
    }

    /// Computes an sha256 digest hash string.
    /// - Parameter data: Input data
    /// - Returns: SHA256 hex digest string
    public static func sha256Digest( _ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Return a random string of hex digits.
    /// - Parameter length: Number of digits in string.
    /// Note: length is capped at 32 internally.
    public static func randomHexDigits(length: Int = 16) -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(length).lowercased()
    }
    
    #if os(iOS)
    @MainActor
    public static var uniqueDeviceID: String {
        String(UIDevice.current.identifierForVendor?.uuidString.replacingOccurrences(of: "-", with: "") ?? "")
    }
 
    #endif
    
    /// Return a name not found in names.
    /// - Parameters:
    ///   - from: set of existing names
    ///   - name: requested name
    ///   - separator: separator
    ///
    /// - Returns: name if not found in from, otherwise returns
    ///                  name<seperator><number>
    ///            where number is the smallest positive integer such that
    ///                  name<seperator><number-1>
    ///            isn't found.
    public static func nextNumberedName(from names: Set<String>, name: String = "Untitled",  separator: String = "-") -> String {
        if !names.contains(name) {
            return name
        }
        
        let prefix = name + separator
        var largest = 0
        for candidate in names {
            if candidate.hasPrefix(prefix),
               let n = Int(candidate.dropFirst(prefix.count)) {
                largest = max(largest, n)
            }
        }
        
        return "\(name)\(separator)\(largest+1)"
    }

    /// Returns name without a numbered extension.
    /// - Parameters:
    ///   - name: name
    ///   - separator: separator.
    ///
    /// - Returns: root if name is  of the form <root><separator><number> and otherwise name.
    ///
    public static func nameWithoutNumberedSeparator(name: String, separator: String = "-") -> String {
        if let range = name.range(of: separator, options: .backwards),
           Int(name[range.upperBound...]) != nil {
            return String(name[..<range.lowerBound])
        }
        return name
    }
    
    fileprivate static func wordToWordList(_ word: String) -> [String] {
        var wordList = splitIntoWords(word)
        wordList.append("")
        wordList.append(word != word.lowercased() ? "1" : "0")
        return wordList
    }
    
    fileprivate static func wordListLessThan(_ lhsKeys: [String], _ rhsKeys: [String]) -> Bool {
        for (i, rkey) in rhsKeys.enumerated() {
            if i == lhsKeys.count {
                return true
            }
            
            let lkey = lhsKeys[i]
            if let lno = Int(lkey),
                let rno = Int(rkey) {
                if lno != rno {
                    return lno < rno
                }
            }
            else if let _ = Int(rkey) {
                return false
            }
            else {
                if lkey != rkey {
                    return lkey < rkey
                }
            }
        }
        return false
    }
    
    /// Return strings in dictionary sorted order.
    ///
    /// - Parameter words: input array
    /// - Returns: sorted output.
    ///
    ///    For example, the following is dictionary order.
    ///    a1
    ///    a2
    ///    A3
    ///    A4
    ///    a11
    ///    A11
    ///    A46
    ///    A46.9
    ///    A47
    ///    A47.9
    ///    a101
    ///    a102
    ///    b11
    static public func dictionarySorted<T : Sequence>(_ words:T) -> [String] where T.Element == String {
        let keys = Dictionary(words.map { ($0, wordToWordList($0)) },
                              uniquingKeysWith: { first, second in second })
        
        func lessThan(_ lhs:String, _ rhs: String) -> Bool {
            guard let lhsKeys = keys[lhs],
                  let rhsKeys = keys[rhs] else {
                    return false
            }
            return wordListLessThan(lhsKeys, rhsKeys)
        }
        
        return words.sorted { lessThan($0, $1) }
    }
    
    /// Compare two strings using dictionary ordering.
    ///
    /// - Parameters:
    ///   - lhs: string
    ///   - rhs: string
    /// - Returns: true if the lhs string is less than the rhs string.
    static public func dictionaryLessThan(_ lhs: String, _ rhs: String) -> Bool {
        return wordListLessThan(wordToWordList(lhs), wordToWordList(rhs))
    }
   
    /// Compare two strings using dictionary ordering.
    ///
    /// - Parameters:
    ///   - lhs: string
    ///   - rhs: string
    ///   - cache: temporary cache storage to speed up processing
    /// - Returns: true if the lhs string is less than the rhs string.
    static public func dictionaryLessThan(_ lhs: String, _ rhs: String, cache: inout [String : [String]]) -> Bool {
        if cache[lhs] == nil {
            cache[lhs] = wordToWordList(lhs)
        }
        if cache[rhs] == nil {
            cache[rhs] = wordToWordList(rhs)
        }
        
        return wordListLessThan(cache[lhs]!, cache[rhs]!)
    }
    
    /// Return a string describing how many there are of something.
    ///
    /// - Parameters:
    ///   - n: number of items
    ///   - item: name of item
    ///   - itemPlural: optional name of multiple items
    /// - Returns: a string of the form "<N> <Items>"
    ///
    /// If itemPlural is not specified, it defaults to item with an 's' at the end.
    static public func countDescription(_ n: Int, item: String, itemPlural: String? = nil) -> String {
        if n == 1 {
            return "1 \(item)"
        }
        else {
            let items = itemPlural ?? "\(item)s"
            return "\(n) \(items)"
        }
    }
}
