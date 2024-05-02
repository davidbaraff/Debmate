//
//  LongPressButton.swift
//  Debmate
//
//  Created by David Baraff on 5/1/24.
//

import Foundation
import SwiftUI

@MainActor
public struct LongPressButton : View {
    let buttonText: String
    let tapAction: () -> ()
    let longPressAction: () -> ()
    
    public init(_ buttonText: String, tapAction: @escaping (() -> ()), longPressAction: @escaping (() -> ())) {
        self.buttonText = buttonText
        self.tapAction = tapAction
        self.longPressAction = longPressAction
    }

    public var body: some View {
        Button(buttonText) {
        }.simultaneousGesture(LongPressGesture().onEnded { _ in
            longPressAction()
        })
        .simultaneousGesture(TapGesture().onEnded { _ in
            tapAction()
        })
    }
}
