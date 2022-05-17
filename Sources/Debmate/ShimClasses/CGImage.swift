//
//  CGImage.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

#if os(Linux)

import Foundation
final public class CGImage {
    public init(width: Int, height: Int) {
    }

    public init(width: Int, height: Int, fillColor: CGColor) {
    }

    public func resized(toSize size: CGSize) -> CGImage? {
        return nil
    }
    
    public init?(from: Data) {
        return nil
    }
    
    public func pngData() -> Data {
        return Data()
    }

    public func jpegData() -> Data {
        return Data()
    }

    public var width: Int { 0 }
    public var height: Int { 0 }
}

#endif
