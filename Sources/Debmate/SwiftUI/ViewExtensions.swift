//
//  ViewExtensions.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import SwiftUI

public extension View {
    func anyView() -> AnyView {
        return AnyView(self)
    }
    
    func hide(when hidden: Bool) -> some View {
        self.disabled(hidden).opacity(hidden ? 0 : 1)
    }
    
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}

