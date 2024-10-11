//
//  TestViews.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import SwiftUI

nonisolated(unsafe) fileprivate var ctr = 0

#if !os(watchOS)
public enum TestViews {
    static public func nextCtr(msg: String? = nil) -> String {
        ctr += 1
        if let msg = msg {
            print("\(Date()): \(msg) [\(ctr)]")
        }
        return "\(ctr)"
    }
    
    public struct CoveredScreen<Content>: View  where Content : View {
        let color: Color
        let content: Content
        
        public init(color: Color, @ViewBuilder content: () -> Content) {
            self.color = color
            self.content = content()
        }

        #if os(iOS) || os(tvOS)
        public init(color: UIColor, @ViewBuilder content: () -> Content) {
            self.color = Color(color)
            self.content = content()
        }
        #else
        public init(color: NSColor, @ViewBuilder content: () -> Content) {
            self.color = Color(color)
            self.content = content()
        }
        #endif

        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Text("").frame(width: geometry.size.width, height: geometry.size.height).background(self.color)
                    self.content
                }
            }
        }
    }
}
#endif

