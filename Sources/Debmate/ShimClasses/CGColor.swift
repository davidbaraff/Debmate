//
//  CGColor.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

#if os(Linux)

import Foundation
final public class CGColor {
    static public let red = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    static public let blue = CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
    static public let green = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
    static public let white = CGColor(gray: 1, alpha: 1)
    static public let black = CGColor(gray: 0, alpha: 1)


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
    
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
}

#endif
