//
//  CGColor.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

#if os(Linux)

import Foundation
final public class CGColor {
    public init(srgbRed red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public convenience init(gray: Double, alpha: Double) {
        self.init(srgbRed: gray, green: gray, blue: gray, alpha: alpha)
    }

    var components: [Double]? {
        [red, green, blue, alpha]
    }
    
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

#endif
