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
        var copy = self
        let c = copy.projectedValue.sink(receiveValue: { (val) in
            do {
                try val.encode(to: encoder)
            } catch {
                fatalErrorForCrashReport("unable to extract value from Published<\(type(of: Value.self))>: \(error)")
            }
            
        })
        c.cancel()
    }
}
