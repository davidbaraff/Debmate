//
//  ObservableValue.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation

/// Wrap a single value inside an ObservableObject.
public class ObservableValue<T> : ObservableObject {
    @Published public var value: T
    
    public init(defaultValue: T) {
        value = defaultValue
    }
}
