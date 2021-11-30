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

    func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool, externalControl: Bool)
    var windowSize: CGSize { get }
    
    #if os(macOS)
    func setCursor(_ cursor: NSCursor?)
    #endif
}

public extension ZoomableScrollViewControl {
    func scrollCenter(to location: CGPoint, zoom: CGFloat?) {
        scrollCenter(to: location, zoom: zoom, animated: true, externalControl: false)
    }
    
    func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool = false) {
        scrollCenter(to: location, zoom: zoom, animated: animated, externalControl: false)
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

    func scrollAndZoom(around rect: CGRect, undershoot: CGFloat = 0.90, horizontalFit: Bool = false,
                       animated: Bool = true, externalControl: Bool = false) {
        let scale = horizontalFit ? windowSize.width / rect.width :
                    min(windowSize.width / rect.width, windowSize.height / rect.height)
        scrollCenter(to: rect.center, zoom: undershoot * scale,
                     animated: animated, externalControl: externalControl)
    }
}

#if os(iOS) || os(tvOS)
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
         editDelegate: Any? = nil,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.contentSize = contentSize
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.configureCallback = configureCallback
        self.content = content
    }
        
    public var body: some View {
        InternalZoomableScrollView(contentSize: contentSize, minMagnification: minZoom, maxMagnification: maxZoom, configureCallback: configureCallback) {
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

fileprivate struct InternalZoomableScrollView<Content : View> : UIViewRepresentable {
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let coordinator: Coordinator

    init(contentSize: CGSize,
         minMagnification: CGFloat = 1/250,
         maxMagnification: CGFloat = 4,
         configureCallback: ((ZoomableScrollViewControl) ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize, configureCallback)
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
        
        coordinator.scrollView.showsVerticalScrollIndicator = true
        coordinator.scrollView.showsHorizontalScrollIndicator = true
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
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        class Control : ZoomableScrollViewControl {
            weak var coordinator: Coordinator?

            init(_ coordinator: Coordinator) {
                self.coordinator = coordinator
            }

            func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool, externalControl: Bool) {
                coordinator?.scrollCenter(to: location, zoom: zoom, animated: animated, externalControl: externalControl)
            }
            
            var windowSize: CGSize {
                coordinator?.scrollView.bounds.size ?? CGSize(1,1)
            }
        }

        let contentSize: CGSize
        let scrollViewState = ZoomableScrollViewState()
        var scrollViewControl: ZoomableScrollViewControl!
        let offset: CGPoint

        var scrollView = UIScrollView()
        var view: UIView!
        var controlCancelKey: Cancellable?
        var rotationCancelKey: Cancellable?
        var refreshHelper: RefreshHelper!
        let configureCallback: ((ZoomableScrollViewControl) ->())?
        var recentTouchLocation = CGPoint.zero
        
        init(_ contentSize: CGSize, _ configureCallback: ((ZoomableScrollViewControl) -> ())?) {
            self.contentSize = contentSize
            self.configureCallback = configureCallback
            self.offset = 0.5 * CGPoint(fromSize: contentSize)
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
        
        func computeVisibleRect() -> CGRect {
            let invZoom = 1.0 / scrollView.zoomScale
            let origin = scrollView.contentOffset * invZoom
            let size = scrollView.bounds.size * invZoom

            var x0 = origin.x
            var x1 = origin.x + size.width
            var y0 = origin.y
            var y1 = origin.y + size.height
            
            if inExternalControl && isAnimating {
                if let previousVisibleRect = previousVisibleRect {
                    if previousVisibleRect.minX < x0 {
                        x0 -= 0.2 * size.width
                    }
                    if previousVisibleRect.maxX > x1 {
                        x1 += 0.2 * size.width
                    }
                    if previousVisibleRect.minY < y0 {
                        y0 -= 0.2 * size.height
                    }
                    if previousVisibleRect.maxY > y1 {
                        y1 += 0.2 * size.height
                    }
                }
                else {
                    x0 -= 0.2 * size.width
                    x1 += 0.2 * size.width
                    y0 -= 0.2 * size.height
                    y1 += 0.2 * size.height
                }
                return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
            }
            else {
                return CGRect(origin: origin, size: size)
            }
        }
 
        func scrollViewStateChanged(treatAsExternal: Bool = false) {
            guard scrollViewState.valid else { return }
            scrollViewState.visibleRect = computeVisibleRect()
            scrollViewState.zoomScale = scrollView.zoomScale
            scrollViewState.invZoomScale = 1.0 / scrollView.zoomScale
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
        private var isAnimating = false
        
        func scrollCenter(to position: CGPoint, zoom: CGFloat? = nil, animated: Bool = false, externalControl: Bool = false) {
            let z = max(min(zoom ?? scrollView.zoomScale, scrollView.maximumZoomScale), scrollView.minimumZoomScale)
            let p = z * position - 0.5 * CGPoint(fromSize: scrollView.bounds.size)
            
            inExternalControl = externalControl
            if animated {
                isAnimating = true
                previousVisibleRect = nil
                UIView.animate(withDuration: animated ? 0.2 : 0.0) {
                    if let zoom = zoom {
                        self.scrollView.zoomScale = zoom
                    }
                    self.scrollView.contentOffset = p
                } completion: { finished in
                    if finished {
                        self.inExternalControl = false
                        self.isAnimating = false
                    }
                }
            }
            else {
                if let zoom = zoom {
                    self.scrollView.zoomScale = zoom
                }
                self.scrollView.contentOffset = p
                inExternalControl = false
            }
        }
   }
}
#endif
