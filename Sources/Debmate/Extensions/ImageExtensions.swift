//
//  ImageExtensions.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation
import CoreGraphics
import SwiftUI

public extension Image {
    init(cgImage: CGImage) {
    #if os(iOS)
    self.init(uiImage: UIImage(cgImage: cgImage))
    #else
    self.init(nsImage: NSImage(cgImage: cgImage, size: NSSize(cgImage.width, cgImage.height)))
    #endif
    }
}
