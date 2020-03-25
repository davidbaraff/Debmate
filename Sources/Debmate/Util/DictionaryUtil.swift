//
//  FileUtil.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation

extension Dictionary {
    public init(overwriting items: [(Self.Key, Self.Value)]) {
        self = Dictionary(items) { first, second in second }
    }
}
