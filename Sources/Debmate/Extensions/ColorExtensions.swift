//
//  ColorExtensions.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import SwiftUI

public extension Color {
    #if os(macOS)
    static let systemBackground = Color(.windowBackgroundColor)
    #else
    static let systemBackground = Color(.secondarySystemBackground)
    #endif
}
