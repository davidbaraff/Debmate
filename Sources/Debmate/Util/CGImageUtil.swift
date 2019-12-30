//
//  CGImageUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import CoreGraphics

extension Util {
    static public func resizeCGImage(_ image: CGImage, toSize size: CGSize) -> CGImage? {
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                      bitsPerComponent: image.bitsPerComponent, bytesPerRow: 0,
                                      space: image.colorSpace!,
                                      bitmapInfo: image.bitmapInfo.rawValue) else {
                                        return nil
        }
        
        let destRect = CGRect(origin: .zero, size: size)
        context.interpolationQuality = .high
        context.draw(image, in: destRect)
        return context.makeImage()
    }
    
    
    /// Returns an image scaled to fit within the given size.
    ///
    /// - Parameters:
    ///   - image: Original image
    ///   - size: size image must fit within
    /// - Returns: optional image
    ///
    /// Note that image already fits within size, then image itself is returned.
    static public func fitCGImage(_ image: CGImage, toSize size: CGSize) -> CGImage? {
        if image.width <= Int(size.width) && image.height <= Int(size.height) {
            return image
        }
        
        let scale = min(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
        return resizeCGImage(image, toSize: scale * CGSize(image.width, image.height))
    }
}
