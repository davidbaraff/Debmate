//
//  DiskCachable.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
#if !os(Linux)
import CoreGraphics
#endif

public protocol DiskCachable {
    func toCachableAny() -> Any
    static func fromCachableAny(_ cachableAny: Any) -> Self?
    static func fromCachableAny(_ cachableAny: Any?) -> Self?
}

public extension DiskCachable {
    static func fromCachableAny(_ cachableAny: Any?) -> Self? {
        guard let a = cachableAny else { return nil }
        return Self.fromCachableAny(a)
    }
}

public extension DiskCachable where Self : RawRepresentable {
    func enumToCachableAny() -> Any {
        return self.rawValue
    }
    
    static func enumFromCachableAny(_ cachableAny: Any) -> Self? {
        if let v = cachableAny as? Self.RawValue {
            return Self(rawValue: v)
        }
        return nil
    }
}

public protocol CodableDiskCachable : DiskCachable, Codable {
}

public extension CodableDiskCachable {
    func toCachableAny() -> Any {
        return (try? JSONEncoder().encode(self)) ?? self
    }
    
    static func fromCachableAny(_ cachableAny: Any) -> Self? {
        if let data = cachableAny as? Data {
            return try? JSONDecoder().decode(Self.self, from: data)
        }
        
        return nil
    }
}

public func decodeFromCachableAny<T>(_ cachableAny: Any) -> T? {
    if  let dt = T.self as? DiskCachable.Type {
        return dt.fromCachableAny(cachableAny) as? T
    }
    else {
        return cachableAny as? T
    }
}

public func encodeAsCachableAny<T>(_ value: T) -> Any {
    if  let value = value as? DiskCachable {
        return value.toCachableAny()
    }
    else {
        return value
    }
}

extension Array : DiskCachable {
    public func toCachableAny() -> Any {
        return self.map { encodeAsCachableAny($0) }
    }
    
    public static func fromCachableAny(_ cachableAny: Any) -> Array? {
        if let array = cachableAny as? [Any] {
            let result:Array = array.compactMap { decodeFromCachableAny($0) }
            return result.count == array.count ? result : nil
        }
        return nil
    }
}

extension Set : DiskCachable {
    public func toCachableAny() -> Any {
        return self.map { encodeAsCachableAny($0) }
    }
    
    public static func fromCachableAny(_ cachableAny: Any) -> Set? {
        if let array = cachableAny as? [Any] {
            let result = Set(array.compactMap { decodeFromCachableAny($0) })
            return result.count == array.count ? result : nil
        }
        return nil
    }
}

extension Dictionary : DiskCachable {
    public func toCachableAny() -> Any {
        return [self.keys.map { encodeAsCachableAny($0) },
                self.values.map { encodeAsCachableAny($0) } ]
    }
    
    public static func fromCachableAny(_ cachableAny: Any) -> Dictionary? {
        if let array = cachableAny as? [Any],
            array.count == 2,
            let anyKeys = array[0] as? [Any],
            let anyValues = array[1] as? [Any] {
            
            let keys:[Dictionary.Key] = anyKeys.compactMap({ decodeFromCachableAny($0) })
            let values:[Dictionary.Value] = anyValues.compactMap({ decodeFromCachableAny($0) })
            
            if keys.count == values.count && keys.count == anyKeys.count {
                return Dictionary(zip(keys, values),
                                  uniquingKeysWith: { first, second in first })
            }
        }
        return nil
    }
}

extension CGPoint : DiskCachable {
    public func toCachableAny() -> Any {
        return [Float(self.x), Float(self.y)]
    }
    
    public static func fromCachableAny(_ cachableAny: Any) -> CGPoint? {
        if let array = cachableAny as? [Any],
            array.count == 2,
            let x = array[0] as? Float,
            let y = array[1] as? Float {
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
        return nil
    }
}

extension CGSize : DiskCachable {
    public func toCachableAny() -> Any {
        return [Float(self.width), Float(self.height)]
    }
    
    public static func fromCachableAny(_ cachableAny: Any) -> CGSize? {
        if let array = cachableAny as? [Any],
            array.count == 2,
            let w = array[0] as? Float,
            let h = array[1] as? Float {
            return CGSize(width: CGFloat(w), height: CGFloat(h))
        }
        return nil
    }
}

extension CGRect : DiskCachable {
    public func toCachableAny() -> Any {
        return [Float(self.origin.x), Float(self.origin.y), Float(self.size.width), Float(self.size.height)]
    }
    
    public static func fromCachableAny(_ cachableAny: Any) -> CGRect? {
        if let array = cachableAny as? [Any],
            array.count == 4,
            let x = array[0] as? Float,
            let y = array[1] as? Float,
            let w = array[2] as? Float,
            let h = array[3] as? Float {
            return CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
        }
        return nil
    }
}
