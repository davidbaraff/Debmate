//
//  StringUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import CryptoKit

extension String {
    /// Return an NSRange that full encompasses the string
    public var fullRange: NSRange {
        return NSRange(location: 0, length: count)
    }
    
    /// Return the string with leading and trailing whitespace trimmed off.
    public var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// Return an ascii-safe version of self
    public var asciiSafe: String {
        return String(self.unicodeScalars.filter { $0.isASCII })
    }
}

fileprivate let regex =  try! NSRegularExpression(pattern: "([0-9]+)|([^0-9]+)")
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
    /// - Warning:  If the passed in string is not UTF8-encodable, the
    /// process will halt with a fatalError().
    public static func md5Digest(_ s: String) -> String {
        guard let messageData = s.data(using: .utf8) else {
            fatalErrorForCrashReport("Failed to convert string into data via utf8 encoding: string is \"\(s)\"")
        }
        return md5Digest(messageData)
    }

    /// Computes an md5 digest hash string.
    /// - Parameter d: Input data
    /// - Returns: md5 digest string
    public static func md5Digest(_ data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
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


