//
//  SimpleError.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

public struct SimpleError : Error, CustomStringConvertible {
    private let details: String
    
    public init(_ details: String) {
        self.details = details
    }
    
    public var description: String {
        return details
    }
}
