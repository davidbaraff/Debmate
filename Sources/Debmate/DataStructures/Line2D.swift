//
//  Line2D.swift
//  Debmate
//
//  Created by David Baraff on 8/28/24.
//

import Foundation

public struct Line2D : Sendable {
    public init(p1: CGPoint, p2: CGPoint) {
        let t = (p2 - p1).normalizedDirection
        normal = CGPoint(-t.y, t.x)
        d = -normal.dotProduct(p1)
    }
    
    public init(normal: CGPoint, d: Double) {
        self.normal = normal
        self.d = d
    }

    public func evaluate(_ p: CGPoint) -> Double {
        normal.dotProduct(p) + d
    }

    public func orientedToward(_ p: CGPoint) -> Line2D {
        evaluate(p) >= 0 ? self : self.inverted
    }

    public var inverted: Line2D {
        Line2D(normal: -normal, d: -d)
    }
    
    private let normal: CGPoint
    private let d: Double
}

