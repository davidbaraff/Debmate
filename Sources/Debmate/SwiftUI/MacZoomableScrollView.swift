//
//  MazZoomableScrollView.swift
//  bigCanvas
//
//  Created by David Baraff on 1/19/21.
//

#if os(macOS)

import Foundation
import SwiftUI
import AppKit
import Combine
import CoreGraphics

/*
 See ZoomableScrollView.swift for the definitions
 of ZoomableScrollViewState and ZoomableScrollViewControl.
 */

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
public struct ZoomableScrollView<Content : View> : NSViewRepresentable {
    public typealias NSViewType = NSView
    
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let coordinator: Coordinator

    
    /// Construct a ZoomableScrollView
    /// - Parameters:
    ///   - contentSize: size of the content held
    ///   - minZoom: minimum allowed magnification
    ///   - maxZoom: maximum allowed magnification
    ///   - content: held content
    public init(contentSize: CGSize,
         minZoom: CGFloat = 1/250,
         maxZoom: CGFloat = 4,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize)
        coordinator.scrollView.minMagnification = minZoom
        coordinator.scrollView.maxMagnification = maxZoom
    }
    
    public func makeCoordinator() -> Coordinator {
        coordinator
    }

    public func makeNSView(context: NSViewRepresentableContext<ZoomableScrollView>) -> NSView {
        let coordinator = context.coordinator
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blue.cgColor

        let scrollView = coordinator.scrollView
        let clipView = DraggableClipView()

        clipView.scrollView = scrollView
        scrollView.contentView = clipView

        scrollView.backgroundColor = NSColor.green
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        
        scrollView.allowsMagnification = true
        scrollView.usesPredominantAxisScrolling = false
        scrollView.magnification = scrollView.minMagnification
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        for a: NSLayoutConstraint.Attribute in [.top, .bottom, .leading, .trailing] {
            view.addConstraint(NSLayoutConstraint(item: view, attribute: a, relatedBy: .equal,
                                                  toItem: scrollView, attribute: a, multiplier: 1.0, constant: 0.0))
        }
        
        let innerView = NSHostingController(rootView: content(coordinator.scrollViewState, coordinator.scrollViewControl)).view
        innerView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = innerView
        
        DispatchQueue.main.async {
            scrollView.frame = view.frame
            innerView.frame = view.frame
            scrollView.contentView.window?.makeFirstResponder(scrollView.contentView)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            coordinator.scrollCenter(to: coordinator.offset, zoom: 1, animated: false)
        }
        
        NotificationCenter.default.addObserver(coordinator,
                                               selector: #selector(Coordinator.viewDidScroll),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)
        
        return view
    }
        
    public func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<ZoomableScrollView>) {
    }

    public class Coordinator: NSObject {
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
        let scrollViewState =  ZoomableScrollViewState()
        var scrollViewControl: Control!
        let offset: CGPoint

        let scrollView = NSScrollView()
        var view: NSView!

        init(_ contentSize: CGSize) {
            self.contentSize = contentSize
            self.offset = 0.5 * CGPoint(fromSize: contentSize)
            super.init()
            scrollViewControl = Control(self)
        }

        func computeVisibleRect() -> CGRect {
            let invZoom = 1.0 / scrollView.magnification
            let origin = scrollView.documentVisibleRect.origin /** invZoom */
            let size = scrollView.bounds.size * invZoom
            return CGRect(origin: origin /* - offset */, size: size)
        }
 
        @objc func viewDidScroll(_ notification: Notification) {
            scrollViewStateChanged()
        }

        func scrollViewStateChanged() {
            scrollViewState.visibleRect = computeVisibleRect()
            scrollViewState.zoomScale = scrollView.magnification
            scrollViewState.invZoomScale = 1.0 / scrollView.magnification
        }
        
        func scrollCenter(to position: CGPoint, zoom: CGFloat? = nil, animated: Bool = false) {
            NSAnimationContext.runAnimationGroup {
                $0.duration = 0.2
                
                let zoomScale = zoom ?? scrollView.magnification
                let p = position - (0.5/zoomScale) * CGPoint(fromSize: scrollView.bounds.size)
                
                if let zoom = zoom {
                    scrollView.animator().magnification = zoom
                }

                scrollView.contentView.animator().setBoundsOrigin(p)
            }
        }
    }
}

fileprivate class DraggableClipView: NSClipView {
    weak var scrollView: NSScrollView!
    
    private var clickPoint: NSPoint?
    private var originalOrigin: NSPoint?
    private var lastZoomPoint = CGPoint.zero
    private var zoomAnchorPoint = CGPoint.zero
    
    private var spaceDown = false
    private var optionDown = false
    private var middleButtonDown = false
    private var mouseDown: Bool { clickPoint != nil }

    override func cursorUpdate(with event: NSEvent) {
        if !spaceDown && !optionDown {
            super.cursorUpdate(with: event)
        }
    }
    
    private func zoomAnchorPoint(screenPoint: CGPoint) -> CGPoint {
        let flippedPoint = CGPoint(screenPoint.x, scrollView.bounds.height - screenPoint.y)
        return scrollView.documentVisibleRect.origin + flippedPoint * (1.0 / scrollView.magnification)
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
        lastZoomPoint = event.locationInWindow
        clickPoint = lastZoomPoint
        originalOrigin = bounds.origin
        zoomAnchorPoint = zoomAnchorPoint(screenPoint: lastZoomPoint)
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

    override func scrollWheel(with event: NSEvent) {
        let p = zoomAnchorPoint(screenPoint: event.locationInWindow)

        if event.scrollingDeltaY > 0 {
            modifyMagnification(event.scrollingDeltaY / 50, zoomIn: true, centeredAt: p)
        }
        else {
            modifyMagnification(-event.scrollingDeltaY / 50, zoomIn: false, centeredAt: p)
        }
    }
    
    func modifyMagnification(_ delta: CGFloat, zoomIn: Bool, centeredAt p: CGPoint) {
        let factor = zoomIn ? (1 + delta) : 1 / (1 + delta)
        scrollView.setMagnification(scrollView.magnification * factor, centeredAt: p)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let clickPoint = clickPoint,
              let originalOrigin = originalOrigin else {
            return
        }

        if !spaceDown && !middleButtonDown {
            if optionDown {
                let curPoint = event.locationInWindow
                let xDelta = curPoint.x - lastZoomPoint.x
                lastZoomPoint = curPoint

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

        // Account for a magnified parent scrollview.
        let scale = (superview as? NSScrollView)?.magnification ?? 1.0
        let newPoint = event.locationInWindow
        let newOrigin = NSPoint(x: originalOrigin.x + (clickPoint.x - newPoint.x) / scale,
                                y: originalOrigin.y - (clickPoint.y - newPoint.y) / scale)
        let constrainedRect = constrainBoundsRect(NSRect(origin: newOrigin, size: bounds.size))
        scroll(to: constrainedRect.origin)
        superview?.reflectScrolledClipView(self)
    }
    
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = documentView {
            
            if rect.size.width > containerView.frame.size.width {
                rect.origin.x = (containerView.frame.width - rect.width) / 2
            }
            
            if rect.size.height > containerView.frame.size.height {
                rect.origin.y = (containerView.frame.height - rect.height) / 2
            }
        }
        return rect
    }
}
#endif

