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
    
    func hideStatusBar() -> some View {
        #if os(iOS)
        return self.statusBar(hidden: true)
        #else
        return self
        #endif
    }
    
    func noAutocapitalization() -> some View {
        #if os(iOS)
        return self.autocapitalization(.none)
        #else
        return self
        #endif
    }
}

