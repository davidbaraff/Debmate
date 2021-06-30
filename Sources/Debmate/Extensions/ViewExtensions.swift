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
    
    func dimAndDisable(when disabled: Bool) -> some View {
        self.disabled(disabled)
            .opacity(disabled ? 0.5 : 1)
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
    
    #if os(iOS) || os(tvOS)
    func cgImageSnapshot() -> CGImage? {
        let controller = UIHostingController(rootView: self)
        let view: UIView = controller.view
        let targetSize = controller.view.intrinsicContentSize
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }.cgImage?.copy(colorSpace: CGColorSpaceCreateDeviceRGB())
    }
    #elseif os(macOS)
    func cgImageSnapshot() -> CGImage? {
        let controller = NSHostingController(rootView: self)
        let targetSize = controller.view.intrinsicContentSize
        let contentRect = NSRect(origin: .zero, size: targetSize)
        
        let w = NSWindow(contentRect: contentRect, styleMask: [.borderless],
                         backing: .buffered, defer: false)
        w.contentView = controller.view
        
        guard let bitmapRep = controller.view.bitmapImageRepForCachingDisplay(in: contentRect) else {
            return nil
        }
        
        controller.view.cacheDisplay(in: contentRect, to: bitmapRep)
        let image = NSImage(size: bitmapRep.size)
        image.addRepresentation(bitmapRep)
        return image.cgImage(forProposedRect: nil, context: nil, hints: [:])
    }
    #endif
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

    #if os(iOS)
    func iOS_blur(radius: CGFloat) -> some View {
        self.blur(radius: radius)
    }
    #else
    func iOS_blur(radius: CGFloat) -> some View {
        self
    }
    #endif

   

    func iOS_preferredColorScheme(_ scheme: ColorScheme?) -> some View {
        #if os(iOS)
        return self.preferredColorScheme(scheme)
        #else
        return self
        #endif
    }
    
    #if os(iOS)
    var platform_iOS: Bool { true }
    var platform_macOS: Bool { false }
    var platform_tvOS: Bool { false }
    #endif

    #if os(macOS)
    var platform_iOS: Bool { false }
    var platform_macOS: Bool { true }
    var platform_tvOS: Bool { false }
    #endif

    #if os(tvOS)
    var platform_iOS: Bool { false }
    var platform_macOS: Bool { false }
    var platform_tvOS: Bool { true }
    #endif

}



