//
//  DebmateConfig.swift
//  Debmate
//
//  Created by David Baraff on 12/28/19.
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

/// Assorted utility free functions.
public enum Util {
}

public struct DebmateError : Error, CustomStringConvertible {
    let msg: String
    
    public init(_ msg: String) {
        self.msg = msg
    }
    
    public var description: String {
        return msg
    }
}
