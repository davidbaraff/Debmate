//
//  ColorExtensions.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

#if !os(Linux)
import SwiftUI

public extension String {
    var asHexColor: Color {
        Color(hex: self)
    }
}

public extension Color {
    #if os(macOS)
    static let systemBackground = Color(.windowBackgroundColor)
    #elseif os(iOS)
    static let systemBackground = Color(.secondarySystemBackground)
    #else
    static let systemBackground = Color(white: 0.3, opacity: 1)
    #endif
}

public extension Color {
    /// Iniialize color from a hex string
    /// - Parameter hex: string in ex (e.g. "ff00ff00")
    /// Leading bytes are alpha, then blue, green, red.
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }

        var int64 = UInt64()
        Scanner(string: hex).scanHexInt64(&int64)
        let int = UInt32(int64 & 0xffffffff)
        let a, b, g, r: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, b, g, r) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, b, g, r) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, b, g, r) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, b, g, r) = (255, 0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
#endif

