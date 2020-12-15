//
//  DataExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import Compression

public extension Data {
    func withCompression(algorithm: compression_algorithm, _ handler: (Data, Bool) -> ()) {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count)
        defer { destinationBuffer.deallocate() }
        self.withUnsafeBytes {
            if let bytes = $0.bindMemory(to: UInt8.self).baseAddress {
                let compressedSize = compression_encode_buffer(destinationBuffer, self.count, bytes,
                                                               self.count, nil, algorithm)
                if compressedSize > 0 && compressedSize < self.count {
                    handler(Data(bytesNoCopy: destinationBuffer, count: compressedSize, deallocator: Data.Deallocator.none), true)
                }
                else {
                    handler(self, false)
                }
            }
        }
    }
    
    func withDecompression(algorithm: compression_algorithm, nbytes: Int, _ handler: (Data) -> ()) {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: nbytes)
        defer { destinationBuffer.deallocate() }
        self.withUnsafeBytes {
            if let bytes = $0.bindMemory(to: UInt8.self).baseAddress {
                _ = compression_decode_buffer(destinationBuffer, nbytes, bytes, self.count, nil, algorithm)
                handler(Data(bytes: destinationBuffer, count: nbytes))
            }
        }
    }
}

