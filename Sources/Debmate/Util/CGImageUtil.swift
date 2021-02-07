//
//  CGImageUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO
#if os(iOS)
import UIKit
#else
import AppKit
#endif

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
    
    /// Resize an image.
    /// - Parameters:
    ///   - fileURL: a file URL containing the image
    ///   - toSize: desired output size
    ///
    /// This function requires direct access to the file URL containing the image,
    /// but is known to work for large images where Debmate.Util.resizeCGImage() does not.
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
    
    /// Returns an image read from an app's asset catalog.
    /// - Parameter named: The name of the image asset or file.
    /// - Returns: an image
    ///
    /// See the documentation for UIImage(named: ) or NSImage(named: ) as appropriate.
    static public func cgImage(named: String) -> CGImage? {
        #if os(iOS)
        return UIImage(named: named)?.cgImage
        #else
        return NSImage(named: named)?.cgImage(forProposedRect: nil, context: nil, hints: [:])
        #endif
    }
    
    /// Create an empty image with a size and fill color.
    ///
    /// - Parameters:
    ///   - fillColor: contents of image
    ///   - size: image size
    /// - Returns: image
    static public func createEmptyImage(width: Int, height: Int, fillColor: CGColor = .clear) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let ctx = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
                                    fatalErrorForCrashReport("failed to create CGContext")
        }
        
        ctx.setBlendMode(.normal)
        ctx.setFillColor(fillColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let finalImage = ctx.makeImage() else {
            fatalErrorForCrashReport("ctx.makeImage() failed")
        }

        return finalImage
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

    /// Recolor an image
    ///
    /// - Parameters:
    ///   - image: input image
    ///   - tint: tint color
    /// - Returns: recolored image
    ///
    /// If there is an issue, the original image is returned.
    static public func tintedImage(_ image: CGImage, tint: CGColor) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        guard let context = CGContext(data: nil, width: image.width, height: image.height,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            print("Failed to create cg context")
                                        return nil
        }
        
        let destRect = CGRect(origin: .zero, size: CGSize(image.width, image.height))
        context.interpolationQuality = .high
        context.draw(image, in: destRect)
        
        // draw alpha-mask
        context.setBlendMode(.normal)
        context.draw(image, in: destRect)
        
        // draw tint color, preserving alpha values of original image
        context.setBlendMode(.sourceIn)
        context.setFillColor(tint)
        context.fill(destRect)
        return context.makeImage()
    }
    
    
    /// Construct a CGImage from Data
    /// - Parameter data: data in some supported format (e.g. jpeg, PNG)
    /// - Returns: cgImage on success
    static public func cgImage(from data: Data) -> CGImage? {
        #if os(iOS)
        return UIImage(data: data)?.cgImage
        #else
        return NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: [:])
        #endif
    }

    /// Construct a CGImage from Data
    /// - Parameter data: data in some supported format (e.g. jpeg, PNG)
    /// - Returns: cgImage on success
    static public func cgImage(from url: URL) -> CGImage? {
        #if os(iOS)
        return UIImage(contentsOfFile: url.path)?.cgImage
        #else
        return NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: [:])
        #endif
    }
    
    /// Convert cgImage to jpeg data
    /// - Parameters:
    ///   - from: input cgImage
    ///   - compressionQuality: 0 is maximally compressed, 1 is maximum image quality
    /// - Returns: <#description#>
    static public func jpegData(from cgImage: CGImage, compressionQuality: CGFloat = 1) -> Data? {
        #if os(iOS)
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: compressionQuality)
        #else
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])
        #endif
    }

    /// Convert cgImage to png data
    /// - Parameters:
    ///   - from: input cgImage
    /// - Returns: <#description#>
    static public func pngData(from cgImage: CGImage) -> Data? {
        #if os(iOS)
        return UIImage(cgImage: cgImage).pngData()
        #else
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        #endif
    }
}



