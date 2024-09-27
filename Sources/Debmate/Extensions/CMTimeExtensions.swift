//
//  CMTimeExtensions.swift
//  Debmate
//
//  Created by David Baraff on 9/9/24.
//

import CoreMedia

public extension CMTime {
    init(seconds: Double) {
        self.init(seconds: seconds, preferredTimescale: 600)
    }
}
