//
//  UnsafeMutablePointerExtensions.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import Compression

extension UnsafeMutablePointer where Pointee == UInt8 {
    public func withCompression(algorithm: compression_algorithm, count: Int, _ handler: (Data, Bool) -> ()) {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { destinationBuffer.deallocate() }
        let compressedSize = compression_encode_buffer(destinationBuffer, count, self,
                                                       count, nil, algorithm)
        if compressedSize > 0 && compressedSize < count {
            handler(Data(bytesNoCopy: destinationBuffer, count: compressedSize, deallocator: Data.Deallocator.none), true)
        }
        else {
            handler(Data(bytesNoCopy: self, count: count, deallocator: Data.Deallocator.none), true)
        }
    }
}
