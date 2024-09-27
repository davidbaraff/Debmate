//
//  TouchDownUpModifier.swift
//  Debmate
//
//  Created by David Baraff on 9/20/24.
//

import Foundation
import SwiftUI

public extension View {
    func onTouchDownUp(pressed: @escaping ((Bool) -> Void)) -> some View {
        self.modifier(TouchDownUpEventModifier(pressed: pressed))
    }
}

fileprivate struct TouchDownUpEventModifier: ViewModifier {
    @State var dragged = false

    var pressed: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !dragged {
                            dragged = true
                            pressed(true)
                        }
                    }
                    .onEnded { _ in
                        dragged = false
                        pressed(false)
                    }
            )
    }
}
