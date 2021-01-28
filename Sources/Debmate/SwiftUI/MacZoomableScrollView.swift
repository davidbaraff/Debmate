//
//  MazZoomableScrollView.swift
//  bigCanvas
//
//  Created by David Baraff on 1/19/21.
//

#if os(macOS)

/*
 See ZoomableScrollView.swift for the definitions
 of ZoomableScrollViewState and ZoomableScrollViewControl.
 */

import Foundation
import SwiftUI
import AppKit
import Combine
import CoreGraphics

/// A ZoomableScrollView adds zoomability and fine-grain scrolling controls to the currently
/// feature-poor version of ScrollView exposed by SwiftUI.
///
/// Example use:
///
///     ZoomableScrollView(contentSize: CGSize) {   (scrollViewState, scrollViewControl) -> AnyView in
///         ZStack {
///            ...
///         }.eraseToAnyVIew()
///      }
///
/// In particular, the passed in scrollViewState and scrollViewControl objects can be used
/// to monitor and control, respectively, the scroll view.

fileprivate let  animationDuration = 0.3

public struct ZoomableScrollView<Content : View> : View {
    let contentSize: CGSize
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let configureCallback: ((ZoomableScrollViewControl) ->())?
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    
    /// Construct a ZoomableScrollView
    /// - Parameters:
    ///   - contentSize: size of the content held
    ///   - minZoom: minimum allowed magnification
    ///   - maxZoom: maximum allowed magnification
    ///   - configureCallback: optional callback shortly after initialization
    ///   - content: held content
    public init(contentSize: CGSize,
         minZoom: CGFloat = 1/250,
         maxZoom: CGFloat = 4,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.contentSize = contentSize
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.configureCallback = configureCallback
        self.content = content
    }
        
    public var body: some View {
        InternalZoomableScrollView(contentSize: contentSize, minZoom: minZoom, maxZoom: maxZoom, configureCallback: configureCallback) {
            (scrollViewState, scrollViewControl) in
            ScaledContentView(scrollViewState: scrollViewState) {
                self.content(scrollViewState, scrollViewControl)
            }
        }
    }
}

fileprivate struct ScaledContentView<Content : View> : View {
    @ObservedObject var scrollViewState: ZoomableScrollViewState
    let content: () -> Content

    init(scrollViewState: ZoomableScrollViewState,
         @ViewBuilder content: @escaping () -> Content) {
        self.scrollViewState = scrollViewState
        self.content = content
    }
    
    var body: some View {
        self.content().scaleEffect(scrollViewState.zoomScale, anchor: .center)
    }
}

fileprivate struct InternalZoomableScrollView<Content : View> : NSViewRepresentable {
    typealias NSViewType = NSView
    
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let coordinator: Coordinator
    
    init(contentSize: CGSize,
         minZoom: CGFloat = 1/250,
         maxZoom: CGFloat = 4,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize, minZoom, maxZoom, configureCallback)
    }
    
    func makeCoordinator() -> Coordinator {
        coordinator
    }

    func makeNSView(context: NSViewRepresentableContext<InternalZoomableScrollView>) -> NSView {
        let coordinator = context.coordinator

        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blue.cgColor

        let scrollView = coordinator.scrollView
        let clipView = coordinator.clipView

        clipView.scrollView = scrollView
        clipView.coordinator = coordinator

        scrollView.contentView = clipView

        scrollView.backgroundColor = NSColor.green
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        
        scrollView.allowsMagnification = false
        scrollView.usesPredominantAxisScrolling = false
        scrollView.contentView.postsFrameChangedNotifications = true

        scrollView.autoresizingMask = NSView.AutoresizingMask(arrayLiteral: .width, .height)
        scrollView.translatesAutoresizingMaskIntoConstraints = true

        for a: NSLayoutConstraint.Attribute in [.top, .bottom, .leading, .trailing] {
            view.addConstraint(NSLayoutConstraint(item: view, attribute: a, relatedBy: .equal,
                                                  toItem: scrollView, attribute: a, multiplier: 1.0, constant: 0.0))
        }
        
        let innerView = NSHostingController(rootView: content(coordinator.scrollViewState, coordinator.scrollViewControl)).view

        innerView.autoresizingMask = NSView.AutoresizingMask(arrayLiteral: .width, .height)
        innerView.translatesAutoresizingMaskIntoConstraints = true

        scrollView.documentView = innerView
        view.addSubview(scrollView)

        scrollView.frame = view.frame
        innerView.frame = view.frame

        DispatchQueue.main.async {
            scrollView.contentView.window?.makeFirstResponder(scrollView.contentView)
            coordinator.scrollViewStateChanged()
        }

        NotificationCenter.default.addObserver(coordinator,
                                               selector: #selector(Coordinator.boundsDidChange),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)

        NotificationCenter.default.addObserver(coordinator,
                                               selector: #selector(Coordinator.boundsDidChange),
                                               name: NSWindow.didResizeNotification,
                                               object: scrollView.window)
        return view
    }
        
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<InternalZoomableScrollView>) {
        DispatchQueue.main.async {
            context.coordinator.viewUpdated()
            context.coordinator.scrollViewStateChanged()
        }
    }
}

fileprivate class Coordinator: NSObject {
    class Control : ZoomableScrollViewControl {
        weak var coordinator: Coordinator?

        init(_ coordinator: Coordinator) {
            self.coordinator = coordinator
        }

        func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool) {
            coordinator?.scrollCenter(to: location, zoom: zoom, animated: animated)
        }
    }
    
    let contentSize: CGSize
    let minMagnification: CGFloat
    let maxMagnification: CGFloat
    let scrollViewState =  ZoomableScrollViewState()
    var scrollViewControl: Control!
    let offset: CGPoint

    let scrollView = NSScrollView()
    var clipView = DraggableClipView()

    let configureCallback: ((ZoomableScrollViewControl) ->())?
    var inConfigureCallback = false

    init(_ contentSize: CGSize, _ minZoom: CGFloat, _ maxZoom: CGFloat, _ configureCallback: ((ZoomableScrollViewControl) -> ())?) {
        self.contentSize = contentSize
        self.minMagnification = minZoom
        self.maxMagnification = maxZoom
        self.configureCallback = configureCallback
        self.offset = 0.5 * CGPoint(fromSize: contentSize)
        super.init()
        scrollViewControl = Control(self)
    }

    func magnifyBy(factor: CGFloat, centeredAt cp: CGPoint) {
        /*
         wl = window location
         nwl = new window location
         cp = center point
         co = content origin
         nco = new content origin (what we're solving for)
         z = current zoom
         f = factor (how much we're zooming up or down,
             i.e. new zoom = z f.
         
         Solve for nco such that wl = nwl.
         
         wl = (cp - co) z
         nwl = (cp - nco) z f
         
         So wl = nwl ==>
            (cp - co) z = (cp - nco) z f
            (cp - co) z = cp z f - nco z f
            nco z f + (cp - co) z = cp z f
            nco z f  = cp z f - (cp - co) z

            nco = (cp z f - (cp - co) z) / zf
                = cp - (cp - co) z / zf
                = cp - (cp - co) / f
                = cp - cp / f + co / f
                = cp (1 - 1/f) + co / f
        */

        let newMagnification = max(min(clipView.currentMagnification * factor, maxMagnification), minMagnification)
        let invF = clipView.currentMagnification / newMagnification
        let newContentOrigin = cp * (1 - invF) + currentOrigin() * invF

        clipView.currentMagnification = newMagnification
        scrollOrigin(to: newContentOrigin)
    }

    func viewUpdated() {
        if !scrollViewState.valid {
            scrollViewState.valid = true
            inConfigureCallback = true
            self.configureCallback?(self.scrollViewControl)
            inConfigureCallback = false
        }
    }
    
    func currentOrigin() -> CGPoint {
        let invZoom = 1.0 / clipView.currentMagnification
        return scrollView.documentVisibleRect.origin * invZoom
    }

    func computeVisibleRect() -> CGRect {
        let invZoom = 1.0 / clipView.currentMagnification
        let origin = scrollView.documentVisibleRect.origin * invZoom
        let size = scrollView.bounds.size * invZoom
        return CGRect(origin: origin, size: size)
    }

    @objc func boundsDidChange(_ notification: Notification) {
        scrollViewStateChanged()
    }

    func scrollViewStateChanged() {
        scrollView.documentView?.frame.size = contentSize  * clipView.currentMagnification
        
        guard scrollViewState.valid else { return }
        scrollViewState.visibleRect = computeVisibleRect()
        scrollViewState.zoomScale = clipView.currentMagnification
        scrollViewState.invZoomScale = 1.0 / clipView.currentMagnification
    }
    
    func scrollOrigin(to position: CGPoint) {
        scrollView.contentView.setBoundsOrigin(position * clipView.currentMagnification)
    }

    func scrollCenter(to position: CGPoint, zoom: CGFloat? = nil, animated: Bool = false) {
        let zoomScale = zoom ?? clipView.currentMagnification
        let p = zoomScale * position - 0.5 * CGPoint(fromSize: scrollView.bounds.size)

        if animated || inConfigureCallback {
            NSAnimationContext.runAnimationGroup {
                $0.duration = inConfigureCallback ? 0.01 : animationDuration
                $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                if let zoom = zoom {
                    clipView.animator().currentMagnification = zoom
                }
                scrollView.contentView.animator().setBoundsOrigin(p)
            }
        }
        else {
            if let zoom = zoom {
                clipView.currentMagnification = zoom
            }
            scrollView.contentView.setBoundsOrigin(p)
        }
        
        scrollViewStateChanged()
    }
}

@objc
fileprivate class DraggableClipView: NSClipView {
    weak var scrollView: NSScrollView!
    weak var coordinator: Coordinator!
    
    private var clickPoint: NSPoint?
    private var originalOrigin: NSPoint?
    private var lastZoomPoint = CGPoint.zero
    private var zoomAnchorPoint = CGPoint.zero
    
    private var spaceDown = false
    private var optionDown = false
    private var middleButtonDown = false
    private var mouseDown: Bool { clickPoint != nil }

    @objc dynamic var currentMagnification = CGFloat(1)
    
    override static func defaultAnimation(forKey key: NSAnimatablePropertyKey) -> Any? {
        if key == "currentMagnification" {
            return CABasicAnimation()
        }
        return super.defaultAnimation(forKey: key)
    }

    override func cursorUpdate(with event: NSEvent) {
        if !spaceDown && !optionDown {
            super.cursorUpdate(with: event)
        }
    }
    
    private func zoomAnchorPoint(contentViewPoint: CGPoint) -> CGPoint {
        return contentViewPoint * (1 / currentMagnification)
    }
    
    override func otherMouseDown(with event: NSEvent) {
        NSCursor.openHand.push()
        mouseDown(with: event)
    }

    override func otherMouseUp(with event: NSEvent) {
        mouseUp(with: event)
        NSCursor.current.pop()
    }

    override func otherMouseDragged(with event: NSEvent) {
        mouseDragged(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        middleButtonDown = event.buttonNumber == (1<<1)
        lastZoomPoint = convert(event.locationInWindow, from: nil)
        clickPoint = event.locationInWindow
        originalOrigin = coordinator.currentOrigin()
        zoomAnchorPoint = zoomAnchorPoint(contentViewPoint: lastZoomPoint)
    }
    
    override func mouseUp(with event: NSEvent) {
        middleButtonDown = false
        clickPoint = nil
        originalOrigin = nil
        
        if spaceDown {
            spaceDown = false
            NSCursor.current.pop()
        }
        if optionDown {
            optionDown = false
            NSCursor.current.pop()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers?.contains(" ") ?? false {
            if !spaceDown {
                spaceDown = true
                NSCursor.openHand.push()
            }
        }
    }

    override func keyUp(with event: NSEvent) {
        if event.charactersIgnoringModifiers?.contains(" ") ?? false {
            if !mouseDown {
                if spaceDown {
                    spaceDown = false
                    NSCursor.current.pop()
                }
            }
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option {
            if !optionDown {
                optionDown = true
                if middleButtonDown {
                    NSCursor.openHand.push()
                }
                else {
                    NSCursor.crosshair.push()
                }
            }
        }
        else {
            if !mouseDown {
                if optionDown {
                    optionDown = false
                    NSCursor.crosshair.pop()
                }
            }
        }
    }
    
    override func magnify(with event: NSEvent) {
        let p = zoomAnchorPoint(contentViewPoint:  convert(event.locationInWindow, from: nil))

        if event.magnification > 0 {
            modifyMagnification(event.magnification, zoomIn: true, centeredAt: p)
        }
        else {
            modifyMagnification(-event.magnification, zoomIn: false, centeredAt: p)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        guard event.subtype == .mouseEvent else {
            super.scrollWheel(with: event)
            return
        }

        let p = zoomAnchorPoint(contentViewPoint:  convert(event.locationInWindow, from: nil))

        if event.scrollingDeltaY > 0 {
            modifyMagnification(event.scrollingDeltaY / 50, zoomIn: true, centeredAt: p)
        }
        else {
            modifyMagnification(-event.scrollingDeltaY / 50, zoomIn: false, centeredAt: p)
        }
    }
    
    func modifyMagnification(_ delta: CGFloat, zoomIn: Bool, centeredAt p: CGPoint) {
        let factor = zoomIn ? (1 + delta) : 1 / (1 + delta)
        coordinator.magnifyBy(factor: factor, centeredAt: p)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let clickPoint = clickPoint,
              let originalOrigin = originalOrigin else {
            return
        }

        if !spaceDown && !middleButtonDown {
            if optionDown {
                let xDelta = event.locationInWindow.x - clickPoint.x
                self.clickPoint = event.locationInWindow

                NSCursor.crosshair.set()
                if xDelta > 0 {
                    modifyMagnification(min(xDelta, 50)/200.0, zoomIn: true, centeredAt: zoomAnchorPoint)
                }
                else {
                    modifyMagnification(min(-xDelta, 50)/200.0, zoomIn: false, centeredAt: zoomAnchorPoint)
                }
            }
            return
        }

        NSCursor.openHand.set()

        // window delta to content space delta (also, window space Y axis is flipped):
        let delta = (event.locationInWindow - clickPoint) * (1 / coordinator.clipView.currentMagnification)
        coordinator.scrollOrigin(to: CGPoint(x: originalOrigin.x - delta.x,
                                             y: originalOrigin.y + delta.y))

        superview?.reflectScrolledClipView(self)
    }

    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        guard let documentView = documentView else { return rect }
        
        if rect.size.width > documentView.frame.size.width {
            rect.origin.x = (documentView.frame.width - rect.width) / 2
        }
        
        if rect.size.height > documentView.frame.size.height {
            rect.origin.y = (documentView.frame.height - rect.height) / 2
        }
        return rect
    }
}
#endif

