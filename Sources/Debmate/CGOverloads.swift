//
//  CGOverloads.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import CoreGraphics

public extension CGSize {
    init(_ x: Int, _ y: Int) {
        self.init(width: x, height: y)
    }
    
    init(_ x: Double, _ y: Double) {
        self.init(width: x, height: y)
    }
    
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(width: x, height: y)
    }
    
    init(fromPoint point: CGPoint) {
        self.init(width: point.x, height: point.y)
    }
}

public extension CGPoint {
    init(_ x: Int, _ y: Int) {
        self.init(x: x, y: y)
    }
    
    init(_ x: Double, _ y: Double) {
        self.init(x: x, y: y)
    }
    
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
    
    init(fromSize size: CGSize) {
        self.init(x: size.width, y:size.height)
    }
}

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public prefix func - (p: CGPoint) -> CGPoint {
    return CGPoint(x: -p.x, y: -p.y)
}

public func * (scale: CGFloat, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: scale * rhs.x, y: scale * rhs.y)
}

public func * (scale: Double, rhs: CGPoint) -> CGPoint {
    return CGFloat(scale) * rhs
}

public func * (scale: Float, rhs: CGPoint) -> CGPoint {
    return CGFloat(scale) * rhs
}

public func * (lhs: CGPoint, scale: CGFloat) -> CGPoint {
    return CGPoint(x: scale * lhs.x, y: scale * lhs.y)
}

public func * (lhs: CGPoint, scale: Float) -> CGPoint {
    return lhs * CGFloat(scale)
}

public func * (lhs: CGPoint, scale: Double) -> CGPoint {
    return lhs * CGFloat(scale)
}

public func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(lhs.width + rhs.width, lhs.height + rhs.height)
}

public func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(lhs.width - rhs.width, lhs.height - rhs.height)
}

public func * (scale: CGFloat, rhs: CGSize) -> CGSize {
    return CGSize(width: scale * rhs.width, height: scale * rhs.height)
}

public func * (scale: Double, rhs: CGSize) -> CGSize {
    return CGFloat(scale) * rhs
}

public func * (scale: Float, rhs: CGSize) -> CGSize {
    return CGFloat(scale) * rhs
}

public func * (lhs: CGSize, scale: CGFloat) -> CGSize {
    return CGSize(width: scale * lhs.width, height: scale * lhs.height)
}

public func * (lhs: CGSize, scale: Float) -> CGSize {
    return lhs * CGFloat(scale)
}

public func * (lhs: CGSize, scale: Double) -> CGSize {
    return lhs * CGFloat(scale)
}

public func / (lhs: CGSize, scale: CGFloat) -> CGSize {
    return lhs * (1.0 / scale)
}

public func / (lhs: CGSize, scale: Float) -> CGSize {
    return lhs * (1.0 / scale)
}

public func / (lhs: CGSize, scale: Double) -> CGSize {
    return lhs * (1.0 / scale)
}

