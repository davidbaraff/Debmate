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
    
    func background<Content: View>(_ background: Content, when enabled: Bool) -> AnyView {
        if enabled {
            return self.background(background).anyView()
        }
        else {
            return self.anyView()
        }
    }
    
    func executeCode(_ code: () -> ()) -> Self {
        code()
        return self
    }
    
    func hide(when hidden: Bool) -> some View {
        self.disabled(hidden).opacity(hidden ? 0 : 1)
    }
    
    func hideStatusBar() -> some View {
        #if os(iOS)
        return self.statusBar(hidden: true)
        #else
        return self
        #endif
    }
    
    func noAutocapitalization() -> some View {
        #if os(iOS) || os(tvOS)
        return self.autocapitalization(.none)
        #else
        return self
        #endif
    }
    
    func frame(size: CGSize) -> some View {
        self.frame(width: size.width, height: size.height)
    }
}

public extension View {
    #if os(tvOS)
    func tvOS_onPlayPauseCommand(perform: @escaping() -> ()) -> some View {
        self.onPlayPauseCommand(perform: perform)
    }
    #else
    func tvOS_onPlayPauseCommand(perform: @escaping() -> ()) -> Self {
        self
    }
    #endif

    #if os(tvOS)
    func tvOS_focusable(_ isFocusable: Bool = true, onFocusChange: @escaping (Bool) -> Void = { _ in }) -> some View {
        self.focusable(isFocusable, onFocusChange: onFocusChange)
    }
    #else
    func tvOS_focusable(_ isFocusable: Bool = true, onFocusChange: @escaping (Bool) -> Void = { _ in }) -> Self {
        self
    }
    #endif
}

