//
//  CGImageUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
#if !os(Linux)
import CoreGraphics
import ImageIO
#endif

#if os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
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
        #if !os(Linux)
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                      bitsPerComponent: image.bitsPerComponent, bytesPerRow: 0,
                                      space: image.colorSpace!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                                        return nil
        }
        
        let destRect = CGRect(origin: .zero, size: size)
        context.interpolationQuality = .high
        context.draw(image, in: destRect)
        return context.makeImage()
        #else
        return image.resized(toSize: size)
        #endif
    }
    
    #if !os(Linux)
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
    #endif
    
    #if !os(Linux)
    /// Returns an image read from an app's asset catalog.
    /// - Parameter named: The name of the image asset or file.
    /// - Returns: an image
    ///
    /// See the documentation for UIImage(named: ) or NSImage(named: ) as appropriate.
    static public func cgImage(named: String) -> CGImage? {
        #if os(iOS) || os(tvOS)
        return UIImage(named: named)?.cgImage
        #else
        return NSImage(named: named)?.cgImage(forProposedRect: nil, context: nil, hints: [:])
        #endif
    }
    #endif
    
    #if !os(Linux)
    static let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    #endif
    
    /// Create a standard 32-bit ARGB context.
    /// - Parameters:
    ///   - width: width in pixels
    ///   - height: height in pixels
    ///   - fillColor: optional fill color to fill context upon creation
    static public func createStandardARGBContext(width: Int, height: Int, fillColor: CGColor? = nil) -> CGContext {
        #if !os(Linux)
        guard let cgContext = CGContext(data: nil, width: width, height: height,
                                        bitsPerComponent: 8, bytesPerRow: 0,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo.rawValue) else {
            fatalErrorForCrashReport("failed to create CGContext")
        }
        
        if let fillColor = fillColor {
            cgContext.setFillColor(fillColor)
            cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return cgContext
        #else
        return CGContext(width: width, height: height)
        #endif
    }
    
    /// Create a standard 32-bit ARGB context.
    /// - Parameters:
    ///   - size: image size (rounded to integer width/height)
    ///   - fillColor: optional fill color to fill context upon creation
    static public func createStandardARGBContext(size: CGSize, fillColor: CGColor? = nil) -> CGContext {
        createStandardARGBContext(width: Int(size.width.rounded()), height: Int(size.height.rounded()), fillColor: fillColor)
    }

    /// Create an empty image with a size and fill color.
    ///
    /// - Parameters:
    ///   - fillColor: contents of image
    ///   - size: image size
    /// - Returns: image
    static public func createEmptyImage(width: Int, height: Int, fillColor: CGColor = .clear) -> CGImage {
        #if !os(Linux)
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
        #else
        return CGImage(width: width, height: height, fillColor: fillColor)
        #endif
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
        #if !os(Linux)
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
        #else
        return image.tinted(tint)
        #endif
    }
    
    /// Construct a CGImage from Data
    /// - Parameter data: data in some supported format (e.g. jpeg, PNG)
    /// - Returns: cgImage on success
    static public func cgImage(from data: Data) -> CGImage? {
        #if os(iOS) || os(tvOS)
        return UIImage(data: data)?.cgImage
        #elseif os(macOS)
        return NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: [:])
        #else
        return CGImage(from: data)
        #endif
    }

    /// Construct a CGImage from Data
    /// - Parameter data: data in some supported format (e.g. jpeg, PNG)
    /// - Returns: cgImage on success
    static public func cgImage(from url: URL) -> CGImage? {
        #if os(iOS) || os(tvOS)
        return UIImage(contentsOfFile: url.path)?.cgImage
        #elseif os(macOS)
        return NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: [:])
        #else
        if let data = try? Data(contentsOf: url) {
            return CGImage(from: data)
        }
        return nil
        #endif
    }
    
    /// Convert cgImage to jpeg data
    /// - Parameters:
    ///   - from: input cgImage
    ///   - compressionQuality: 0 is maximally compressed, 1 is maximum image quality
    /// - Returns: <#description#>
    static public func jpegData(from cgImage: CGImage, compressionQuality: CGFloat = 1) -> Data? {
        #if os(iOS) || os(tvOS)
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])
        #else
        return cgImage.jpegData()
        #endif
    }

    /// Convert cgImage to png data
    /// - Parameters:
    ///   - from: input cgImage
    /// - Returns: <#description#>
    static public func pngData(from cgImage: CGImage) -> Data? {
        #if os(iOS) || os(tvOS)
        return UIImage(cgImage: cgImage).pngData()
        #elseif os(macOS)
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        #else
        return cgImage.pngData()
        #endif
    }
}
