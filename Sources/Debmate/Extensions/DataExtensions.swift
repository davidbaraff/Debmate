//
//  DataExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

#if !os(Linux)

import Foundation
import Compression

public extension Data {
    func decodedJSONObject(options: JSONSerialization.ReadingOptions = [.mutableContainers]) throws -> Any {
        try JSONSerialization.jsonObject(with: self, options: options)
    }
    
    /// Safely convert data directly to string by considering the data as the string's UTF8 view
    var asUTF8String: String {
        String(decoding: self, as: UTF8.self)
    }

    @discardableResult
    func withCompression<T>(algorithm: compression_algorithm, forceCompression: Bool = false, _ handler: (Data, Bool) throws -> (T)) throws -> T? {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count)
        defer { destinationBuffer.deallocate() }
        return try self.withUnsafeBytes {
            if let bytes = $0.bindMemory(to: UInt8.self).baseAddress {
                let compressedSize = compression_encode_buffer(destinationBuffer, self.count, bytes,
                                                               self.count, nil, algorithm)
                if forceCompression || (compressedSize > 0 && compressedSize < self.count) {
                    return try handler(Data(bytesNoCopy: destinationBuffer, count: compressedSize, deallocator: Data.Deallocator.none), true)
                }
                else {
                    return try handler(self, false)
                }
            }
            return nil
        }
    }

    @discardableResult
    func withCompression<T>(algorithm: compression_algorithm, forceCompression: Bool = false, _ handler: (Data, Bool) -> (T)) -> T? {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count)
        defer { destinationBuffer.deallocate() }
        return self.withUnsafeBytes {
            if let bytes = $0.bindMemory(to: UInt8.self).baseAddress {
                let compressedSize = compression_encode_buffer(destinationBuffer, self.count, bytes,
                                                               self.count, nil, algorithm)
                if forceCompression || (compressedSize > 0 && compressedSize < self.count) {
                    return handler(Data(bytesNoCopy: destinationBuffer, count: compressedSize, deallocator: Data.Deallocator.none), true)
                }
                else {
                    return handler(self, false)
                }
            }
            return nil
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
#endif

