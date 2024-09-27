//
//  SimdExtensions.swift
//  Debmate
//
//  Created by David Baraff on 9/9/24.
//

import Foundation
import simd

public extension simd_float4x4 {
    var translation: SIMD3<Float> {
        .init(self.columns.3.x, self.columns.3.y, self.columns.3.z)
    }
}

public extension SIMD3<Float> {
    var magnitude: Float {
        sqrt(x*x + y*y + z*z)
    }
    
    var normalized: SIMD3<Float> {
        self / magnitude
    }
}

public struct SIMDPlane {
    // normal * p + d = 0
    let normal: SIMD3<Float>
    let d: Float
    
    public init(normal: SIMD3<Float>, point: SIMD3<Float>) {
        self.normal = normal.normalized
        d = -simd_dot(normal, point)
    }
    
    public func evaluate(point: SIMD3<Float>) -> Float {
        simd_dot(normal, point) + d
    }
    
    public func intersection(line: SIMDLine) -> SIMD3<Float>? {
        let n_dir = simd_dot(line.direction, normal)
        guard abs(n_dir) > 1e-5 else { return nil }
        let t = -(d + simd_dot(normal, line.p)) / n_dir
        return line.p + t * line.direction
    }
}

public struct SIMDLine {
    let p: SIMD3<Float>
    let direction: SIMD3<Float>
    
    public init(_ p0: SIMD3<Float>, _ p1: SIMD3<Float>) {
        p = p0
        direction = (p1 - p0).normalized
    }
}
