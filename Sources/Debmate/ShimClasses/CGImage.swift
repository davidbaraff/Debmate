//
//  CGImage.swift
//  Debmate
//
//  Copyright © 2022 David Baraff. All rights reserved.
//

#if os(Linux)

import DebmateLinuxQT

import Foundation
final public class CGImage {
    public let qImagePtr: UnsafeRawPointer

    public init(width: Int, height: Int) {
        guard let imagePtr = linuxQT_empty_image(Int32(width), Int32(height)) else {
            fatalErrorForCrashReport("Failed to construct empty image of size \(width) X \(height)")
        }
        qImagePtr = imagePtr
    }

    public convenience init(width: Int, height: Int, fillColor: CGColor) {
        self.init(width: width, height: height)
    }

    public func clone() -> CGImage {
        return CGImage(linuxQT_image_copy(qImagePtr), "CGImage.clone()")
    }

    func tinted(_ color: CGColor) -> CGImage {
        return CGImage(linuxQT_tinted_image(qImagePtr, color.redInt32, color.greenInt32, color.blueInt32, color.alphaInt32),
                       "CGImage.tinted()")
    }

    deinit {
        linuxQT_delete_image(qImagePtr)
    }

    private init(_ imagePtr: UnsafeRawPointer?, _ description: String) {
        guard let imagePtr = imagePtr else {
            fatalErrorForCrashReport("Received null image ptr in init from \(description)")
        }
        qImagePtr = imagePtr
    }

    public func resized(toSize size: CGSize) -> CGImage? {
        let width = Int32(size.width)
        let height = Int32(size.height)
        guard width > 0, height > 0 else { return nil }
        return CGImage(linuxQT_resize_image(qImagePtr, width, height), "CGImage.resized(toSize:)")
    }
    
    public init?(from data: Data) {
        let imagePtr: UnsafeRawPointer? = data.withUnsafeBytes { // (ptr: UnsafeRawBufferPointer) in
            return linuxQT_image_from_data($0.baseAddress, Int32(data.count))
        }

        guard let imagePtr = imagePtr else {
           return nil
        }

        qImagePtr = imagePtr
    }
    
    public func pngData() -> Data {
        guard let byteArray = linuxQT_image_to_pngData(qImagePtr),
              let bytes = linuxQT_byte_array_data(byteArray) else {
            fatalErrorForCrashReport("Unable to produce PNG data for CGImage")
        }
        defer { linuxQT_delete_byte_array(byteArray) }
        return Data(bytes: bytes, count: Int(linuxQT_byte_array_size(byteArray)))
    }

    public func jpegData() -> Data {
        guard let byteArray = linuxQT_image_to_jpgData(qImagePtr),
              let bytes = linuxQT_byte_array_data(byteArray) else {
            fatalErrorForCrashReport("Unable to produce PNG data for CGImage")
        }
        defer { linuxQT_delete_byte_array(byteArray) }
        return Data(bytes: bytes, count: Int(linuxQT_byte_array_size(byteArray)))
    }

    public var width: Int { Int(linuxQT_image_width(qImagePtr)) }
    public var height: Int { Int(linuxQT_image_height(qImagePtr)) }
}

#endif
