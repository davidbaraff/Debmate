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

/// A delegate for the cut/copy/paste/selectAll/delete edit menu functionality.
/// If queryOnly is true, the function should not do anything but return true or false
/// to indicate if the corresponding edit menu entry should be enabled or not.
///
/// If queryOnly is false, an actual edit operation should be performed.
public protocol ZoomableScrollViewEditDelegate : AnyObject {
    func copy(queryOnly: Bool) -> Bool
    func paste(queryOnly: Bool) -> Bool
    func cut(queryOnly: Bool) -> Bool
    func selectAll(queryOnly: Bool) -> Bool
    func delete(queryOnly: Bool) -> Bool
    func currentModifiers(modifierFlags: NSEvent.ModifierFlags)
    func keyPress(unicodeScalarValue: UInt32)
}

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
    let editDelegate: ZoomableScrollViewEditDelegate?
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
         editDelegate: ZoomableScrollViewEditDelegate? = nil,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.contentSize = contentSize
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.editDelegate = editDelegate
        self.configureCallback = configureCallback
        self.content = content
    }
        
    public var body: some View {
        InternalZoomableScrollView(contentSize: contentSize, minZoom: minZoom, maxZoom: maxZoom,
                                   editDelegate: editDelegate, configureCallback: configureCallback) {
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
         editDelegate: ZoomableScrollViewEditDelegate?,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize, minZoom, maxZoom, configureCallback, editDelegate)
    }
    
    func makeCoordinator() -> Coordinator {
        coordinator
    }

    func makeNSView(context: NSViewRepresentableContext<InternalZoomableScrollView>) -> NSView {
        let coordinator = context.coordinator

        let view = NSView()
        let mouseHitView = MouseHitView()
        
        let scrollView = coordinator.scrollView
        let clipView = coordinator.clipView

        mouseHitView.clipView = clipView
        mouseHitView.editDelegate = coordinator.editDelegate
        clipView.scrollView = scrollView
        clipView.coordinator = coordinator

        scrollView.contentView = clipView

        scrollView.backgroundColor = NSColor.clear
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true

        scrollView.allowsMagnification = false
        scrollView.usesPredominantAxisScrolling = false
        scrollView.contentView.postsFrameChangedNotifications = true

        scrollView.autoresizingMask = NSView.AutoresizingMask(arrayLiteral: .width, .height)
        scrollView.translatesAutoresizingMaskIntoConstraints = true

        mouseHitView.autoresizingMask = NSView.AutoresizingMask(arrayLiteral: .width, .height)
        mouseHitView.translatesAutoresizingMaskIntoConstraints = true

        for a: NSLayoutConstraint.Attribute in [.top, .bottom, .leading, .trailing] {
            view.addConstraint(NSLayoutConstraint(item: view, attribute: a, relatedBy: .equal,
                                                  toItem: scrollView, attribute: a, multiplier: 1.0, constant: 0.0))
            view.addConstraint(NSLayoutConstraint(item: view, attribute: a, relatedBy: .equal,
                                                  toItem: mouseHitView, attribute: a, multiplier: 1.0, constant: 0.0))
        }
        
        let innerView = NSHostingController(rootView: content(coordinator.scrollViewState, coordinator.scrollViewControl)).view

        innerView.autoresizingMask = NSView.AutoresizingMask(arrayLiteral: .width, .height)
        innerView.translatesAutoresizingMaskIntoConstraints = true

        scrollView.documentView = innerView
        
        view.addSubview(scrollView)
        view.addSubview(mouseHitView)
        
        scrollView.frame = view.frame
        innerView.frame = view.frame
        coordinator.scrollView.drawsBackground = false
        coordinator.mouseHitView = mouseHitView

        DispatchQueue.main.async {
            scrollView.contentView.window?.makeFirstResponder(mouseHitView)
            coordinator.scrollViewStateChanged(treatAsExternalControl: true)
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
            context.coordinator.scrollViewStateChanged(treatAsExternalControl: true)
        }
    }
}

fileprivate class Coordinator: NSObject {
    class Control : ZoomableScrollViewControl {
        var windowSize: CGSize {
            return coordinator?.actualScrollViewSize ?? CGSize(1,1)
        }
        
        weak var coordinator: Coordinator?

        init(_ coordinator: Coordinator) {
            self.coordinator = coordinator
        }

        func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool, externalControl: Bool) {
            coordinator?.scrollCenter(to: location, zoom: zoom, animated: animated, externalControl: externalControl)
        }
    }
    
    let contentSize: CGSize
    let minMagnification: CGFloat
    let maxMagnification: CGFloat
    let scrollViewState =  ZoomableScrollViewState()
    var scrollViewControl: Control!
    weak var mouseHitView: MouseHitView!
    let offset: CGPoint

    let scrollView = NSScrollView()
    var clipView = DraggableClipView()
    var cachedScrollViewSize: CGSize?
    
    var actualScrollViewSize: CGSize {
        if let cachedScrollViewSize = cachedScrollViewSize {
            return cachedScrollViewSize
        }
        
        let scrollerHeight = scrollView.horizontalScroller?.bounds.height ?? 0
        let scrollerWidth = scrollView.verticalScroller?.bounds.width ?? 0
        if let actualWindowHeight = clipView.window?.contentLayoutRect.height {
            let delta = CGSize(width: scrollerWidth,
                           height: clipView.bounds.height - (actualWindowHeight - scrollerHeight))
            var s = scrollView.bounds.size - delta
            s.height = actualWindowHeight - scrollerHeight
            cachedScrollViewSize = s
            return s
        }
        else {
            cachedScrollViewSize = scrollView.bounds.size
            return scrollView.bounds.size
        }
    }
    
    let editDelegate: ZoomableScrollViewEditDelegate?
    let configureCallback: ((ZoomableScrollViewControl) ->())?
    var inConfigureCallback = false

    init(_ contentSize: CGSize, _ minZoom: CGFloat, _ maxZoom: CGFloat, _ configureCallback: ((ZoomableScrollViewControl) -> ())?,
         _ editDelegate: ZoomableScrollViewEditDelegate?) {
        self.contentSize = contentSize
        self.minMagnification = minZoom
        self.maxMagnification = maxZoom
        self.editDelegate = editDelegate
        self.configureCallback = configureCallback
        self.offset = 0.5 * CGPoint(fromSize: contentSize)
        super.init()
        scrollViewControl = Control(self)
        
        scrollViewState.recentTouchLocation = { [weak self] in
            return self?.currentMouseLocation() ?? .zero
        }
    }

    private func currentMouseLocation() -> CGPoint {
        guard let mousePt = scrollView.window?.mouseLocationOutsideOfEventStream else {
            return .zero
        }
        
        // Hot spot of the arrow cursor appears offset a tad:
        let p = scrollView.convert(CGPoint(mousePt.x - 2, mousePt.y + 13), from: nil)
        let invZoom = 1.0 / clipView.currentMagnification
        let origin = scrollView.documentVisibleRect.origin * invZoom
        return origin + p * invZoom
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
            mouseHitView.becomeFirstResponder()
        }
    }
    
    func currentOrigin() -> CGPoint {
        let invZoom = 1.0 / clipView.currentMagnification
        return scrollView.documentVisibleRect.origin * invZoom
    }

    func computeVisibleRect() -> CGRect {
        let scrollerHeight = scrollView.horizontalScroller?.bounds.height ?? 0
        let scrollerWidth = scrollView.verticalScroller?.bounds.width ?? 0
        var delta = CGSize.zero
        if let actualWindowHeight = clipView.window?.contentLayoutRect.height {
            delta = CGSize(width: scrollerWidth,
                           height: clipView.bounds.height - (actualWindowHeight - scrollerHeight))
        }

        let invZoom = 1.0 / clipView.currentMagnification
        let origin = (scrollView.documentVisibleRect.origin + CGPoint(x: 0, y: delta.height)) * invZoom
        let size = (scrollView.bounds.size - delta) * invZoom
        return CGRect(origin: origin, size: size)
    }

    @objc func boundsDidChange(_ notification: Notification) {
        cachedScrollViewSize = nil
        scrollViewStateChanged()
    }

    func scrollViewStateChanged(treatAsExternalControl: Bool = false) {
        scrollView.documentView?.frame.size = contentSize  * clipView.currentMagnification
        
        guard scrollViewState.valid else { return }
        scrollViewState.visibleRect = computeVisibleRect()
        scrollViewState.zoomScale = clipView.currentMagnification
        scrollViewState.invZoomScale = 1.0 / clipView.currentMagnification
        scrollViewState.externalControl = inExternalControl || treatAsExternalControl
    }
    
    func scrollOrigin(to position: CGPoint) {
        scrollView.contentView.setBoundsOrigin(position * clipView.currentMagnification)
    }

    private var inExternalControl = false
    
    func scrollCenter(to position: CGPoint, zoom: CGFloat? = nil, animated: Bool = false, externalControl: Bool = false) {
        let zoomScale = max(min(zoom ?? clipView.currentMagnification, maxMagnification), minMagnification)
        var p = zoomScale * position - 0.5 * CGPoint(fromSize: actualScrollViewSize)

        if let actualWindowHeight = clipView.window?.contentLayoutRect.height {
            let scrollerHeight = scrollView.horizontalScroller?.bounds.height ?? 0
            let ydelta = clipView.bounds.height - (actualWindowHeight - scrollerHeight)
            p = CGPoint(p.x, p.y - ydelta)
        }
        
        if (animated && !externalControl) || inConfigureCallback {
            NSAnimationContext.runAnimationGroup {
                $0.duration = inConfigureCallback ? 0.01 : animationDuration
                $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                if zoom != nil {
                    clipView.animator().currentMagnification = zoomScale
                }
                scrollView.contentView.animator().setBoundsOrigin(p)
            }
        }
        else {
            if zoom != nil {
                clipView.currentMagnification = zoomScale
            }
            scrollView.contentView.setBoundsOrigin(p)
        }
        
        inExternalControl = externalControl
        scrollViewStateChanged()
        inExternalControl = false
    }
}

extension NSEvent {
    static var leftButtonDown: Bool { (NSEvent.pressedMouseButtons & 01) == 01 }
    static var middleButtonDown: Bool { (NSEvent.pressedMouseButtons & 04) == 04 }
    static var rightButtonDown: Bool { (NSEvent.pressedMouseButtons & 02) == 02 }
}

@objc fileprivate class MouseHitView : NSView {
    weak var clipView: DraggableClipView!
    weak var editDelegate: ZoomableScrollViewEditDelegate?
    
    override var acceptsFirstResponder: Bool { true }
    
    /*
    @objc
    override func selectAll(_ sender: Any?) {
        editDelegate?.selectAll(queryOnly: false)
    }

    @objc
    func delete(_ sender: Any?) {
        editDelegate?.delete(queryOnly: false)
    }


    @objc
    func paste(_ sender: Any?) {
        editDelegate?.paste(queryOnly: false)
    }

    @objc
    func copy(_ sender: Any?) {
        editDelegate?.copy(queryOnly: false)
    }

    @objc
    func cut(_ sender: Any?) {
        editDelegate?.cut(queryOnly: false)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(paste) {
            return editDelegate?.paste(queryOnly: true) ?? false
        }

        if aSelector == #selector(copy(_:)) {
            return editDelegate?.copy(queryOnly: true) ?? false
        }

        if aSelector == #selector(cut) {
            return editDelegate?.cut(queryOnly: true) ?? false
        }

        if aSelector == #selector(selectAll) {
            return editDelegate?.selectAll(queryOnly: true) ?? false
        }

        if aSelector == #selector(delete) {
            return editDelegate?.selectAll(queryOnly: true) ?? false
        }
        return super.responds(to: aSelector)
    }*/
        
    private func updateCursor() {
        if clipView.spaceDown {
            if NSEvent.rightButtonDown {
                clipView.setCursor(to: clipView.plusCursor)
            }
            else {
                clipView.setCursor(to: .openHand)
            }
        }
        else if clipView.optionDown {
            if NSEvent.middleButtonDown {
                clipView.setCursor(to: .openHand)
            }
            else if NSEvent.rightButtonDown {
                clipView.setCursor(to: clipView.plusCursor)
            }
        }
        else {
            clipView.setCursor(to: nil)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers?.contains(" ") ?? false {
            clipView.spaceDown = true
            updateCursor()
        }

        if let v = event.characters?.first?.unicodeScalars.first?.value {
            editDelegate?.keyPress(unicodeScalarValue: v)
        }
    }

    override func keyUp(with event: NSEvent) {
        if event.charactersIgnoringModifiers?.contains(" ") ?? false {
            clipView.spaceDown = false
            updateCursor()
        }
    }

    override func flagsChanged(with event: NSEvent) {
        clipView.optionDown = event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option
        updateCursor()
        editDelegate?.currentModifiers(modifierFlags: event.modifierFlags)
    }

    override func rightMouseDown(with event: NSEvent) {
        clipView.capturedDown = true
        clipView.rightMouseDown(with: event)
        updateCursor()
    }

    override func rightMouseUp(with event: NSEvent) {
        clipView.rightMouseUp(with: event)
        clipView.capturedDown = false
        updateCursor()
    }

    override func rightMouseDragged(with event: NSEvent) {
        clipView.rightMouseDragged(with: event)
    }
    
    override func otherMouseDown(with event: NSEvent) {
        clipView.capturedDown = true
        clipView.otherMouseDown(with: event)
        updateCursor()
    }

    override func otherMouseUp(with event: NSEvent) {
        clipView.otherMouseUp(with: event)
        clipView.capturedDown = false
        updateCursor()
    }

    override func otherMouseDragged(with event: NSEvent) {
        clipView.otherMouseDragged(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        if clipView.spaceDown {
            clipView.capturedDown = true
            clipView.mouseDown(with: event)
        }
        else {
            super.mouseDown(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if clipView.capturedDown {
            clipView.mouseUp(with: event)
            clipView.capturedDown = false
        }
        else {
            super.mouseUp(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        if clipView.capturedDown {
            clipView.mouseDragged(with: event)
        }
        else {
            super.mouseDragged(with: event)
        }
    }
    
    override func magnify(with event: NSEvent) {
        clipView.magnify(with: event)
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
    
    private var pushedCursor = false
    var spaceDown = false
    var optionDown = false
    var capturedDown = false
    private var middleButtonDown = false
    private var rightButtonDown = false
    private var mouseDown: Bool { clickPoint != nil }

    let plusCursor: NSCursor
    let minusCursor: NSCursor

    @objc dynamic var currentMagnification = CGFloat(1)

    override init(frame: NSRect) {
        guard let plusCursorURL = Bundle.module.url(forResource: "plus.magnifyingglass", withExtension: "png") else {
            fatalErrorForCrashReport("DragableClipView failed to locate resource file for plus magnifying glass cursor image")
        }
        guard let minusCursorURL = Bundle.module.url(forResource: "minus.magnifyingglass", withExtension: "png") else {
            fatalErrorForCrashReport("DragableClipView failed to locate resource file for minus magnifying glass cursor image")
        }
        guard let plusCursorImage = NSImage(contentsOfFile: plusCursorURL.path) else {
            fatalErrorForCrashReport("DragableClipView failed to create plus magnifying glass image from resource file")
        }
        guard let minusCursorImage = NSImage(contentsOfFile: minusCursorURL.path) else {
            fatalErrorForCrashReport("DragableClipView failed to create minus magnifying glass image from resource file")
        }

        plusCursor = NSCursor(image: plusCursorImage, hotSpot: NSPoint(0, 0))
        minusCursor = NSCursor(image: minusCursorImage, hotSpot: NSPoint(0,0))

        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalErrorForCrashReport("init(coder:) has not been implemented")
    }
    
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
    
    func setCursor(to cursor: NSCursor?) {
        if pushedCursor {
            NSCursor.pop()
        }
        if let cursor = cursor {
            pushedCursor = true
            cursor.push()
        }
    }

    private func zoomAnchorPoint(contentViewPoint: CGPoint) -> CGPoint {
        return contentViewPoint * (1 / currentMagnification)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        mouseDown(with: event)
    }

    override func rightMouseUp(with event: NSEvent) {
        mouseUp(with: event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        mouseDragged(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        mouseDown(with: event)
    }

    override func otherMouseUp(with event: NSEvent) {
        mouseUp(with: event)
    }

    override func otherMouseDragged(with event: NSEvent) {
        mouseDragged(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        guard capturedDown else { return }
        middleButtonDown = (NSEvent.pressedMouseButtons & 04) != 0
        rightButtonDown = (NSEvent.pressedMouseButtons & 02) != 0

        lastZoomPoint = convert(event.locationInWindow, from: nil)
        clickPoint = event.locationInWindow
        originalOrigin = coordinator.currentOrigin()
        zoomAnchorPoint = zoomAnchorPoint(contentViewPoint: lastZoomPoint)
    }
    
    override func mouseUp(with event: NSEvent) {
        guard capturedDown else { return }
        middleButtonDown = false
        rightButtonDown = false
        clickPoint = nil
        originalOrigin = nil
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
            setCursor(to: plusCursor)
            modifyMagnification(event.scrollingDeltaY / 50, zoomIn: true, centeredAt: p)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.setCursor(to: nil)
            }
        }
        else {
            setCursor(to: minusCursor)
            modifyMagnification(-event.scrollingDeltaY / 50, zoomIn: false, centeredAt: p)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.setCursor(to: nil)
            }
        }
    }
    
    func modifyMagnification(_ delta: CGFloat, zoomIn: Bool, centeredAt p: CGPoint) {
        let factor = zoomIn ? (1 + delta) : 1 / (1 + delta)
        coordinator.magnifyBy(factor: factor, centeredAt: p)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard capturedDown else { return }
        guard let clickPoint = clickPoint,
              let originalOrigin = originalOrigin else {
            return
        }

        if rightButtonDown {
            if spaceDown || optionDown {
                let xDelta = event.locationInWindow.x - clickPoint.x
                self.clickPoint = event.locationInWindow

                if xDelta > 0 {
                    setCursor(to: plusCursor)
                    modifyMagnification(min(xDelta, 50)/200.0, zoomIn: true, centeredAt: zoomAnchorPoint)
                }
                else {
                    setCursor(to: minusCursor)
                    modifyMagnification(min(-xDelta, 50)/200.0, zoomIn: false, centeredAt: zoomAnchorPoint)
                }
            }
            return
        }

        setCursor(to: .openHand)

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

