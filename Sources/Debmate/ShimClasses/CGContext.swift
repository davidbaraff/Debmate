//
//  CGContext.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

#if os(Linux)

import DebmateLinuxQT

fileprivate struct IntRect {
    let x: Int32
    let y: Int32
    let width: Int32
    let height: Int32
}

extension CGRect {
    fileprivate var intRect: IntRect {
        let x = minX.roundedInt
        let y = minY.roundedInt
        return IntRect(x: Int32(x), y: Int32(y), width: Int32(maxX.roundedInt - x), height: Int32(maxY.roundedInt - y))
    }
}

extension CGColor {
    var redInt32: Int32 { Int32((red * 255).rounded()) }
    var greenInt32: Int32 { Int32((green * 255).rounded()) }
    var blueInt32: Int32 { Int32((blue * 255).rounded()) }
    var alphaInt32: Int32 { Int32((alpha * 255).rounded()) }
}


import Foundation
final public class CGContext {
    let cgImage: CGImage

    public init(width: Int, height: Int) {
        cgImage = CGImage(width: width, height: height)
    }

    public func draw(_ image: CGImage, in rect: CGRect) {
        let intRect = rect.intRect

        linuxQT_image_draw(cgImage.qImagePtr, image.qImagePtr, alpha,
                           intRect.x, intRect.y, intRect.width, intRect.height)
    }
    
    public func makeImage() -> CGImage? {
        return cgImage.clone()
    }
    
    public private(set) var fillColor = CGColor.clear
    public private(set) var alpha: Double = 1
    public private(set) var lineWidth: Double = 1
    public private(set) var strokeColor = CGColor.redColor

    public func setFillColor(_ color: CGColor) {
        fillColor = color
    }
    
    public func fill(_ rect: CGRect) {
        let intRect = rect.intRect
        linuxQT_image_fill(cgImage.qImagePtr,
                           fillColor.redInt32, fillColor.greenInt32, fillColor.blueInt32, fillColor.alphaInt32,
                           alpha,
                           intRect.x, intRect.y, intRect.width, intRect.height)
    }

    public func fill(_ rectangles: [CGRect]) {
        for r in rectangles {
            fill(r)
        }
    }

    public func setAlpha(_ alpha: Double) {
        self.alpha = alpha
    }
    
    public func drawFilledCircle(center: CGPoint, radius: Double) {
        linuxQT_image_circle(cgImage.qImagePtr,
                             fillColor.redInt32, fillColor.greenInt32, fillColor.blueInt32, fillColor.alphaInt32,
                             alpha,
                             center.x, center.y, radius)
    }
    
    public func setLineWidth(_ lineWidth: Double) {
        self.lineWidth = lineWidth
    }

    public func setStrokeColor(_ color: CGColor) {
        strokeColor = color
    }
    
    public func stroke(_ rect: CGRect) {
        let intRect = rect.intRect
        linuxQT_image_stroke(cgImage.qImagePtr, lineWidth,
                           strokeColor.redInt32, strokeColor.greenInt32, strokeColor.blueInt32, strokeColor.alphaInt32,
                           alpha,
                           intRect.x, intRect.y, intRect.width, intRect.height)

    }
}

#endif
