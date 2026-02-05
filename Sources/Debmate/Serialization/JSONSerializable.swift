//
//  JSONSerializable.swift
//  Debmate
//
//  Created by David Baraff on 12/17/24.
//

import Foundation

public protocol JSONSerializable : Codable {
}

public extension JSONSerializable {
    func jsonData(sortedKeys: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        if sortedKeys {
            encoder.outputFormatting = [.sortedKeys]
        }
        
        return try encoder.encode(self)
    }

    static func fromJSONData(_ data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}
