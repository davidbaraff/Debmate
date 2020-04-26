//
//  DarkModeFix.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import SwiftUI

extension Published : Codable where Value : Codable {
    public init(from decoder: Decoder) throws {
        self = Published(initialValue: try Value(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        let mirror = Mirror(reflecting: self)

        guard let valueChild = mirror.children.first(where: { $0.label == "value" }),
            let value = valueChild.value as? Encodable else {
                fatalErrorForCrashReport("unable to extract value from Published<\(type(of: Value.self))>")
        }
        try value.encode(to: encoder)
    }
}
