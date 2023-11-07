//
//  ZoomableScrollView.swift
//  bigCanvas
//
//  Created by David Baraff on 1/19/21.
//

import Foundation
import SwiftUI
#if os(iOS) || os(tvOS)
import UIKit
#endif
import Combine
import CoreGraphics


/// Class for observing state changes on a ZoomableScrollView.
public class ZoomableScrollViewState : ObservableObject{
    @Published public var zoomScale = CGFloat(1)
    @Published public var invZoomScale = CGFloat(1)
    @Published public var visibleRect = CGRect.zero
    @Published public var trueVisibleRect = CGRect.zero
    
    public var externalControl = false

    public var contentOffset: CGPoint {
        CGPoint(visibleRect.midX, visibleRect.midY)
    }
    
    public func viewSpaceLocation(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - visibleRect.origin.x) * zoomScale,
                y: (p.y - visibleRect.origin.y) * zoomScale)
    }


    public internal (set) var valid = false
    
    public internal (set) var recentTouchLocation: (() -> CGPoint)!
    
    public init() {
        
    }
}

/// Class for controlling a ZoomableScrollView.
public protocol ZoomableScrollViewControl : AnyObject {
    /// Scroll and zoom the view.
    /// - Parameters:
    ///   - location: location in content space which should be centered in the view
    ///   - zoom: desired zoom level if not nil
    ///   - animated: if the scroll/zoom should be animated
    ///   - externalControl: if the update to the ZoomableScrollViewState
    ///     for this view should set extenralControl to true.  (Do not
    ///     set both animated and externalControl to true in the same call.)

    func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool, externalControl: Bool,
                      completion: (() -> ())?)
    var windowSize: CGSize { get }
    
    #if os(macOS)
    func setCursor(_ cursor: NSCursor?)
    #endif
}

public extension ZoomableScrollViewControl {
    func scrollCenter(to location: CGPoint, zoom: CGFloat?, completion: (() -> ())? = nil) {
        scrollCenter(to: location, zoom: zoom, animated: true, externalControl: false,
                     completion: completion)
    }
    
    func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool = false,
                      completion: (() ->())? = nil) {
        scrollCenter(to: location, zoom: zoom, animated: animated, externalControl: false,
                     completion: completion)
    }
    
    /// Scroll view to fit around a rectangle
    /// - Parameters:
    ///   - rect: rectangle to be centered on screen
    ///   - undershoot: zoom is set to undershoot*actualZoom where actualZom
    ///     is the largest zoom that fits the rectangle completely inside the view
    ///   - horizontalFit: if true, computes the fit only using the horizontal axis
    ///   - animated: if the scroll/zoom should be animated
    ///   - externalControl: if the update to the ZoomableScrollViewState
    ///     for this view should set extenralControl to true.  (Do not
    ///     set both animated and externalControl to true in the same call.)
    ///   - completion: called when the animation completes, or right away if not animated.

    func scrollAndZoom(around rect: CGRect, undershoot: CGFloat = 0.90, horizontalFit: Bool = false,
                       animated: Bool = true, externalControl: Bool = false, completion: (() -> ())? = nil) {
        let windowSize = windowSize
        let scale = horizontalFit ? windowSize.width / rect.width :
                    min(windowSize.width / rect.width, windowSize.height / rect.height)
        scrollCenter(to: rect.center, zoom: undershoot * scale,
                     animated: animated, externalControl: externalControl,
                     completion: completion)
    }
}

#if os(iOS) || os(tvOS)
public protocol ZoomableScrollViewEditDelegate : AnyObject {
    var viewLocked: Bool { get }
}

/// A ZoomableScrollView adds zoomability and fine-grain scrolling controls to the currently
/// feature-poor version of ScrollView exposed by SwiftUI.
///
/// Example use:
///
///     ZoomableScrollView(contentSize: CGSize) {   (scrollViewState, scrollViewControl) -> AnyView in
///         ZStack {
///              ...
///         }.eraseToAnyVIew()
///     }
///
/// In particular, the passed in scrollViewState and scrollViewControl objects can be used
/// to monitor and control, respectively, the scroll view.
public struct ZoomableScrollView<Content : View> : View {
    let contentSize: CGSize
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let configureCallback: ((ZoomableScrollViewControl) ->())?
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let editDelegate: ZoomableScrollViewEditDelegate?
    
    /// Construct a ZoomableScrollView
    /// - Parameters:
    ///   - contentSize: size of the content held
    ///   - minZoom: minimum allowed magnification
    ///   - maxZoom: maximum allowed magnification
    ///   - editDelegate: this parameter is ignored
    ///   - configureCallback: optional callback shortly after initialization
    ///   - content: held content
    public init(contentSize: CGSize,
         minZoom: CGFloat = 1/250,
         maxZoom: CGFloat = 4,
         editDelegate: ZoomableScrollViewEditDelegate? = nil,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.contentSize = contentSize
        #if os(tvOS)
        self.minZoom = minZoom / 10     // avoid bounce because bouncesZoom appears to be broken...
        #else
        self.minZoom = minZoom
        #endif
        self.maxZoom = maxZoom
        self.editDelegate = editDelegate
        self.configureCallback = configureCallback
        self.content = content
    }
        
    public var body: some View {
        InternalZoomableScrollView(contentSize: contentSize, minMagnification: minZoom, maxMagnification: maxZoom,
                                   editDelegate: editDelegate,
                                   configureCallback: configureCallback) {
            (scrollViewState, scrollViewControl) in
            UpdatableContentView(scrollViewState: scrollViewState) {
               self.content(scrollViewState, scrollViewControl)
            }
        }
    }
}

fileprivate struct UpdatableContentView<Content : View> : View {
    // We don't care about the scrollview state, but because updateUIView() causes
    // this object to mutate, we can handle dynamic content in the view held by the
    // call to UpdateContentView(), just above here.
    @ObservedObject var scrollViewState: ZoomableScrollViewState
    let content: () -> Content

    init(scrollViewState: ZoomableScrollViewState,
         @ViewBuilder content: @escaping () -> Content) {
        self.scrollViewState = scrollViewState
        self.content = content
    }
    
    var body: some View {
        self.content()
    }
}

fileprivate class TouchSpyingView : UIView {
    var registerTouchLocation: ((CGPoint) -> ())!
    weak var scrollView: UIScrollView!
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        registerTouchLocation(point - superview!.bounds.origin)
        let touchType = event?.allTouches?.first?.type
        if #available(iOS 14.0, *) {
            if touchType != .indirectPointer && touchType != .pencil {
                let location = point - superview!.bounds.origin
                let edgeTouch = location.x <= 0.1 * UIScreen.main.bounds.width ||
                        location.x >= 0.9 * UIScreen.main.bounds.width ||
                        location.y <= 0.1 * UIScreen.main.bounds.height ||
                            location.y >= 0.85 * UIScreen.main.bounds.height
                scrollView.isDirectionalLockEnabled = edgeTouch
            }
            else {
                scrollView.isDirectionalLockEnabled = false
            }
        }
        return nil
    }
}

fileprivate class LockableUIScrollView : UIScrollView, UIGestureRecognizerDelegate {
    var editDelegate: ZoomableScrollViewEditDelegate?

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        !(editDelegate?.viewLocked ?? false)
    }


    /*
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !(editDelegate?.viewLocked ?? false) {
            super.touchesBegan(touches, with: event)
        }
    }*/

    /*
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
     if editDelegate?.viewLocked ?? false {
         return nil
     }
        return super.hitTest(point, with: event)
    }*/
        
    /*
    override func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
        if editDelegate?.viewLocked ?? false {
            return false
        }
        return super.touchesShouldBegin(touches, with: event, in: view)
    }*/
}

fileprivate struct InternalZoomableScrollView<Content : View> : UIViewRepresentable {
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let coordinator: Coordinator
    
    init(contentSize: CGSize,
         minMagnification: CGFloat = 1/250,
         maxMagnification: CGFloat = 4,
         editDelegate: ZoomableScrollViewEditDelegate?,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize, configureCallback, editDelegate: editDelegate)
        coordinator.scrollView.minimumZoomScale = minMagnification
        coordinator.scrollView.maximumZoomScale = maxMagnification
    }
    
    func makeCoordinator() -> Coordinator {
        return coordinator
    }
    
    func makeUIView(context: UIViewRepresentableContext<InternalZoomableScrollView>) -> UIScrollView {
        let coordinator = context.coordinator
        let view = UIHostingController(rootView: content(coordinator.scrollViewState, coordinator.scrollViewControl)).view!

        coordinator.view = view
        coordinator.watchScrollViewState()
        view.backgroundColor = .clear
        
        coordinator.scrollView.delegate = coordinator
        coordinator.scrollView.isDirectionalLockEnabled = false
        coordinator.scrollView.zoomScale = 1.0

        #if os(tvOS)
        coordinator.scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        #else
        coordinator.scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        #endif
        
        coordinator.scrollView.showsVerticalScrollIndicator = false
        coordinator.scrollView.showsHorizontalScrollIndicator = false
        coordinator.scrollView.translatesAutoresizingMaskIntoConstraints = false
        coordinator.scrollView.backgroundColor = .clear
        coordinator.scrollView.addSubview(view)
    
        let touchSpyingView = TouchSpyingView()
        touchSpyingView.backgroundColor = UIColor(red: 0.2, green: 0, blue: 0, alpha: 0.5)
        touchSpyingView.translatesAutoresizingMaskIntoConstraints = false
        coordinator.scrollView.addSubview(touchSpyingView)
        
        coordinator.scrollView.contentSize = coordinator.contentSize
        coordinator.scrollView.contentOffset = .zero
        view.frame.size = coordinator.contentSize
        touchSpyingView.frame.size = coordinator.scrollView.frame.size

        touchSpyingView.registerTouchLocation = { [weak coordinator] location in
            guard let coordinator = coordinator else { return }
            let invZoom = 1.0 / coordinator.scrollView.zoomScale
            let origin = coordinator.scrollView.contentOffset * invZoom
            coordinator.recentTouchLocation = origin + invZoom * location
        }
        touchSpyingView.scrollView = coordinator.scrollView
        
        return coordinator.scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: UIViewRepresentableContext<InternalZoomableScrollView>) {
        context.coordinator.centerScrollViewContents()
        DispatchQueue.main.async {
            context.coordinator.centerScrollViewContents()
            context.coordinator.viewUpdated()
            context.coordinator.scrollViewStateChanged(treatAsExternal: true)
        }
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        class Control : ZoomableScrollViewControl {
            weak var coordinator: Coordinator?

            init(_ coordinator: Coordinator) {
                self.coordinator = coordinator
            }

            func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool, externalControl: Bool, completion: (() -> ())?) {
                coordinator?.scrollCenter(to: location, zoom: zoom, animated: animated, externalControl: externalControl,
                                          completion: completion)
            }
            
            var windowSize: CGSize {
                coordinator?.scrollView.bounds.size ?? CGSize(1,1)
            }
        }

        let contentSize: CGSize
        let editDelegate: ZoomableScrollViewEditDelegate?
        let scrollViewState = ZoomableScrollViewState()
        var scrollViewControl: ZoomableScrollViewControl!
        let offset: CGPoint

        let scrollView: LockableUIScrollView
        var view: UIView!
        var rotationCancelKey: Cancellable?
        var refreshHelper: RefreshHelper!
        let configureCallback: ((ZoomableScrollViewControl) ->())?
        var recentTouchLocation = CGPoint.zero
        
        
        init(_ contentSize: CGSize, _ configureCallback: ((ZoomableScrollViewControl) -> ())?, editDelegate: ZoomableScrollViewEditDelegate?) {
            self.contentSize = contentSize
            self.configureCallback = configureCallback
            self.editDelegate = editDelegate
            self.offset = 0.5 * CGPoint(fromSize: contentSize)
            self.scrollView = LockableUIScrollView()
            self.scrollView.bounces = false
            self.scrollView.bouncesZoom = false
            self.scrollView.editDelegate = editDelegate
            super.init()
            #if os(iOS)
            scrollView.scrollsToTop = false
            #endif
            scrollViewControl = Control(self)
            scrollViewState.recentTouchLocation = { [weak self] in
                return self?.recentTouchLocation ?? .zero
            }
        }
    
        func watchScrollViewState() {
        #if os(iOS)
            rotationCancelKey = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification).sink {
                [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.scrollViewStateChanged()
                }
            }
        #endif
        }

        func viewUpdated() {
            if !scrollViewState.valid {
                scrollViewState.valid = true
                self.configureCallback?(self.scrollViewControl)
            }
        }
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return view
        }

        var previousVisibleRect: CGRect?
        
        func computeVisibleRect(zoomScale: CGFloat? = nil, contentOffset: CGPoint? = nil) -> CGRect {
            let invZoom = 1.0 / (zoomScale ?? scrollView.zoomScale)
            let origin = (contentOffset ?? scrollView.contentOffset) * invZoom
            let size = scrollView.bounds.size * invZoom
            return CGRect(origin: origin, size: size)
        }
 
        func scrollViewStateChanged(treatAsExternal: Bool = false, zoomScale: CGFloat? = nil, contentOffset: CGPoint? = nil) {
            guard scrollViewState.valid else { return }
            let visibleRect = computeVisibleRect(zoomScale: zoomScale, contentOffset: contentOffset)
            guard scrollViewState.visibleRect != visibleRect else { return }
            scrollViewState.visibleRect = visibleRect
            scrollViewState.trueVisibleRect = visibleRect

            scrollViewState.zoomScale = scrollView.zoomScale
            scrollViewState.invZoomScale = 1.0 / (zoomScale ?? scrollView.zoomScale)
            scrollViewState.externalControl = inExternalControl || treatAsExternal
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollViewStateChanged()
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerScrollViewContents()
            scrollViewStateChanged()
        }
        
        func centerScrollViewContents() {
            let boundsSize = scrollView.bounds.size
            var contentsFrame = view.frame
            
            if contentsFrame.size.width < boundsSize.width {
                contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
            } else {
                contentsFrame.origin.x = 0.0
            }
            
            if contentsFrame.size.height < boundsSize.height {
                contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
            } else {
                contentsFrame.origin.y = 0.0
            }
            
            view.frame = contentsFrame
        }
        
        private var inExternalControl = false
        var startingZoomScale = 1.0
        var endingZoomScale = 1.0
        var startingContentOffset = CGPoint.zero
        var endingContentOffset = CGPoint.zero
        
        var curDisplayLink: CADisplayLink?
        var cumulativeTime = 0.0
        var minZoomScale = 1.0
        let animationDuration = 0.3
        
        @objc func step(displayLink: CADisplayLink) {
            cumulativeTime += displayLink.targetTimestamp - displayLink.timestamp

            let t = min(cumulativeTime / animationDuration, 1)
            let fraction = 2 * (t - 0.5 * t * t)
            let interpolatedZoomScale = startingZoomScale * (1 - fraction) + endingZoomScale * fraction
            let interpolatedContentOffset = startingContentOffset * (1 - fraction) + endingContentOffset * fraction

            scrollView.zoomScale = interpolatedZoomScale
            scrollView.contentOffset = interpolatedContentOffset

            if t >= 1 {
                displayLink.invalidate()
                curDisplayLink = nil
                inExternalControl = false
                #if !os(tvOS)
                scrollView.minimumZoomScale = minZoomScale
                #endif
            }
        }

        func scrollCenter(to position: CGPoint, zoom: CGFloat? = nil, animated: Bool = false, externalControl: Bool = false,
                          completion: (() -> ())? = nil) {
            let z = max(min(zoom ?? scrollView.zoomScale, scrollView.maximumZoomScale), scrollView.minimumZoomScale)
            let p = z * position - 0.5 * CGPoint(fromSize: scrollView.bounds.size)
            
            inExternalControl = externalControl
            if inExternalControl && animated {
                if curDisplayLink == nil {
                    #if !os(tvOS)
                    minZoomScale = scrollView.minimumZoomScale
                    scrollView.minimumZoomScale = scrollView.minimumZoomScale / 10      // bouncesZoom set false doesn't seem to stop bouncing...
                    #endif
                    startingZoomScale = scrollView.zoomScale
                    endingZoomScale = zoom ?? startingZoomScale

                    startingContentOffset = scrollView.contentOffset
                    endingContentOffset = p

                    let displayLink = CADisplayLink(target: self, selector: #selector(step))
                    cumulativeTime = 0
                    displayLink.add(to: .current, forMode: .default)
                    curDisplayLink = displayLink
                }
                else {
                    startingZoomScale = scrollView.zoomScale
                    endingZoomScale = zoom ?? startingZoomScale
                    startingContentOffset = scrollView.contentOffset
                    endingContentOffset = p
                    cumulativeTime = 0
                }
            }
            else if animated {
                UIView.animate(withDuration: animated ? 0.3 : 0.0) {
                    if let zoom = zoom {
                        self.scrollView.zoomScale = zoom
                    }
                    self.scrollView.contentOffset = p
                } completion: { finished in
                    if finished {
                        self.inExternalControl = false
                        completion?()
                    }
                }
            }
            else {
                if let zoom = zoom {
                    self.scrollView.zoomScale = zoom
                }
                self.scrollView.contentOffset = p
                inExternalControl = false
                completion?()
            }
        }
   }
}
#endif
