//
//  CGImageUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO

extension Util {
    /// Resize a CG Image.
       /// - Parameters:
       ///   - image: original image
       ///   - size: output size
       ///
       /// Note: this function is known to be buggy on iOS on sufficiently big images.
       /// This appears to be a flaw in the CoreGraphics libraries.  For images larger
       /// than 12K pixels, consider using the function below (which requires reading the data
       /// from a file).
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
    
    /// Resize an image
    /// - Parameters:
    ///   - fileURL: a file URL containing the image
    ///   - toSize: desired output size
    ///
    /// This function requires direct access to the file URL containing the image,
    /// but is known to work for large images where Debware.Util.resizeCGImage() does not.
    static public func resizeImage(fileURL url: URL, toSize size: CGSize) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: false,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
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
