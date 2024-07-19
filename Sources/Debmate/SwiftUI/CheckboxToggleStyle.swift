//
//  CheckboxToggleStyle.swift
//  Debmate
//
//  Created by David Baraff on 4/20/24.
//

import Foundation
import SwiftUI

public struct CheckboxToggleStyle: ToggleStyle {
    @ScaledMetric var size = 16
    
    public init() {
    }

    public func makeBody(configuration: Configuration) -> some View {
        return HStack {
            configuration.label
            Spacer()

            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .foregroundColor(configuration.isOn ? .blue : .blue)
                .frame(width: size, height: size)
               
        }.onTapGesture { withAnimation { configuration.isOn.toggle() } }
    }
}
