//
//  GeneralError.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation


/// General error type that simply holds a string description.
public struct GeneralError : Error, CustomStringConvertible, LocalizedError {
    private let details: String
    
    public init(_ details: String) {
        self.details = details
    }
    
    public var description: String {
        return details
    }

    public var errorDescription: String? {
        self.description
    }
}
