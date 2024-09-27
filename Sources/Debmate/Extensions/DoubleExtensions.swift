//
//  DoubleExtensions.swift
//  Debmate
//
//  Created by David Baraff on 9/20/24.
//

public extension Double {
    var asDegrees: Double {
        self * 180 / Double.pi
    }
    
    var asRadians: Double {
        self * Double.pi / 180
    }
}
