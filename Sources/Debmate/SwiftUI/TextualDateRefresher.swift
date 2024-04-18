//
//  TextualDateRefresher.swift
//  Debmate
//
//  Created by David Baraff on 3/15/24.
//

import SwiftUI

final public class TextualDateRefresher : ObservableObject {
    private var timer: Debmate.Timer!

    public init(refreshInterval seconds: Int) {
        timer = Timer {
            self.objectWillChange.send()
        }
        timer.start(repeating: Double(seconds))
    }
}


