//
//  File.swift
//  
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation

public extension Date {
    init(secondsSince1970 seconds: Int) {
        self.init(timeIntervalSince1970: Double(seconds))
    }
    
    var secondsSince1970: Int {
        timeIntervalSince1970.roundedInt
    }
    
    var secondsAgo: Double { -timeIntervalSinceNow }
}

public extension Int {
    var asDate: Date { Date(secondsSince1970: self) }
}
