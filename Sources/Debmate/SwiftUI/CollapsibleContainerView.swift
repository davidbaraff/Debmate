//
//  CollapsibleContainerView.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Foundation
import SwiftUI

#if !os(watchOS)

#if os(macOS)
fileprivate let systemBlue = Color.primary
#else
fileprivate let systemBlue = Color(UIColor.systemBlue)
#endif

public struct CollapsibleContainerView<Label, Content> : View where Label : View, Content : View {
    let label: Label
    let content: Content

    @Binding var collapsed: Bool
    @State var chevronAngle: Double = 90
    @State var height = Double.infinity

    public init(isCollapsed collapsed: Binding<Bool>,
                @ViewBuilder label: () -> Label,
                @ViewBuilder content: () -> Content) {
        self._collapsed = collapsed
        self.content = content()
        self.label = label()
    }

    public var body: some View {
        VStack {
            HStack {
                label
                Spacer()
                Button(action: {
                    collapsed.toggle()
                    withAnimation {
                        chevronAngle = collapsed ? 0 : 90
                        height = collapsed ? 0 : .infinity
                    }
                }) {
                    #if os(macOS)
                    if #available(macOS 11.0, *) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(systemBlue)
                            .rotationEffect(Angle(degrees: chevronAngle))
                    } else {
                        Text(">")
                            .foregroundColor(systemBlue)
                            .rotationEffect(Angle(degrees: chevronAngle))
                    }
                    #else
                        Image(systemName: "chevron.right")
                            .foregroundColor(systemBlue)
                            .rotationEffect(Angle(degrees: chevronAngle))
                    #endif
                }
                #if os(macOS)
                .buttonStyle(BorderlessButtonStyle())
                #endif
            }
            VStack {
                content
                Spacer()
            }.frame(maxHeight: height)
             .hide(when: height < 30)
             .clipped()
        }//.fixedSize(horizontal: false, vertical: true)
         .onAppear {
             DispatchQueue.main.async {
                 chevronAngle = collapsed ? 0 : 90
                 height = collapsed ? 0 : .infinity
             }
         }
    }
}

#endif

