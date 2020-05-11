//
//  VideoUtil.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import CoreGraphics
import AVKit

fileprivate func pixelBuffer(fromImage image: CGImage, size: CGSize) throws -> CVPixelBuffer {
    let options: CFDictionary = [kCVPixelBufferCGImageCompatibilityKey as String: true,
                                 kCVPixelBufferCGBitmapContextCompatibilityKey as String: true] as CFDictionary
    var pxbuffer: CVPixelBuffer?

    guard CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                              kCVPixelFormatType_32ARGB, options, &pxbuffer) == kCVReturnSuccess,
          let buffer = pxbuffer else {
            throw GeneralError("CVPixelBufferCreate failed")
    }
    
    CVPixelBufferLockBaseAddress(buffer, [])
    guard let pxdata = CVPixelBufferGetBaseAddress(buffer) else {
        throw GeneralError("CVPixelBufferGetBaseAddress failed")
    }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height),
                            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                            space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
        throw GeneralError("CGContext() failed")
    }

    context.concatenate(CGAffineTransform(rotationAngle: 0))
    context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    CVPixelBufferUnlockBaseAddress(buffer, [])
    return buffer
}

extension Util {
    /// Save an image as a one frame movie
    /// - Parameters:
    ///   - cgImage: input image
    ///   - outputFileURL: output file
    ///   - duration: duration of the single-frame movie produced
    /// - Returns: true on success
    static public func saveImageAsOneFrameMovie(cgImage: CGImage, outputFileURL: URL, duration: TimeInterval = 1.0 / 24.0,
                                                completionHandler: @escaping () ->()) throws {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let videoWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mov)
        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                            AVVideoWidthKey: imageSize.width,
                                            AVVideoHeightKey: imageSize.height]
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
        
        guard videoWriter.canAdd(videoWriterInput) else {
            throw GeneralError("videoWriter.canAdd() failed")
        }

        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriter.add(videoWriterInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let buffer = try pixelBuffer(fromImage: cgImage, size: imageSize)

        adaptor.append(buffer, withPresentationTime: .zero)
        videoWriterInput.markAsFinished()

        videoWriter.finishWriting {
            completionHandler()
        }
    }
}
