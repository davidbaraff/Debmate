//
//  ZoomableScrollView.swift
//  bigCanvas
//
//  Created by David Baraff on 1/19/21.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif
import Combine
import CoreGraphics


/// Class for observing state changes on a ZoomableScrollView.
public class ZoomableScrollViewState : ObservableObject{
    @Published public var zoomScale = CGFloat(1)
    @Published public var invZoomScale = CGFloat(1)
    @Published public var visibleRect = CGRect.zero
    
    public var contentOffset: CGPoint {
        CGPoint(visibleRect.midX, visibleRect.midY)
    }
    
    public internal (set) var valid = false
}

/// Class for controlling a ZoomableScrollView.
public protocol ZoomableScrollViewControl {
    /// Scroll and zoom the view.
    /// - Parameters:
    ///   - location: location in content space which should be centered in the view
    ///   - zoom: desired zoom level if not nil
    ///   - animated: if the scroll/zoom should be animated
    func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool)
}

public extension ZoomableScrollViewControl {
    func scrollCenter(to location: CGPoint, zoom: CGFloat?) {
        scrollCenter(to: location, zoom: zoom, animated: true)
    }
}

#if os(iOS)
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
public struct ZoomableScrollView<Content : View> : UIViewRepresentable {
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let coordinator: Coordinator

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
         configureCallback: (() ->())? = nil,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize, configureCallback)
        coordinator.scrollView.minimumZoomScale = minZoom
        coordinator.scrollView.maximumZoomScale = maxZoom
    }
    
    public func makeCoordinator() -> Coordinator {
        return coordinator
    }
    
    public func makeUIView(context: UIViewRepresentableContext<ZoomableScrollView>) -> UIScrollView {
        let coordinator = context.coordinator
        let view = UIHostingController(rootView: content(coordinator.scrollViewState, coordinator.scrollViewControl)).view!

        coordinator.view = view
        coordinator.watchScrollViewsState()
        
        coordinator.scrollView.delegate = coordinator
        coordinator.scrollView.isDirectionalLockEnabled = false
        coordinator.scrollView.zoomScale = 1.0

        coordinator.scrollView.showsVerticalScrollIndicator = true
        coordinator.scrollView.showsHorizontalScrollIndicator = true
        coordinator.scrollView.translatesAutoresizingMaskIntoConstraints = false
        coordinator.scrollView.backgroundColor = .clear
        coordinator.scrollView.addSubview(view)
    
        coordinator.scrollView.contentSize = coordinator.contentSize
        coordinator.scrollView.contentOffset = .zero
        view.frame.size = coordinator.contentSize
        
        return coordinator.scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: UIViewRepresentableContext<ZoomableScrollView>) {
        DispatchQueue.main.async {
            coordinator.viewUpdated()
        }
    }
    
    public class Coordinator: NSObject, UIScrollViewDelegate {
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
        let scrollViewState = ZoomableScrollViewState()
        var scrollViewControl: ZoomableScrollViewControl!
        let offset: CGPoint

        var scrollView = UIScrollView()
        var view: UIView!
        var controlCancelKey: Cancellable?
        var rotationCancelKey: Cancellable?
        var refreshHelper: RefreshHelper!
        var allowRecenter = false
        let configureCallback: (() ->())?
        
        public init(_ contentSize: CGSize, _ configureCallback: (() -> ())?) {
            self.contentSize = contentSize
            self.configureCallback = configureCallback
            self.offset = 0.5 * CGPoint(fromSize: contentSize)
            super.init()
            scrollViewControl = Control(self)
        }
    
        func watchScrollViewsState() {
            rotationCancelKey = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification).sink {
                [weak self] _ in

                if let self = self,
                   self.allowRecenter {
                    let vr = self.computeVisibleRect()
                    let center = CGPoint(x: vr.midX, y: vr.midY)
                    DispatchQueue.main.async {
                        self.scrollCenter(to: center)
                        self.scrollViewStateChanged()
                    }
                }
            }
        }
    
        func viewUpdated() {
            if !scrollViewState.valid {
                scrollViewState.valid = true
                self.configureCallback?()
            }
        }
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return view
        }

        func computeVisibleRect() -> CGRect {
            let invZoom = 1.0 / scrollView.zoomScale
            let origin = scrollView.contentOffset * invZoom
            let size = scrollView.bounds.size * invZoom
            return CGRect(origin: origin, size: size)
        }
 
        func scrollViewStateChanged() {
            guard scrollViewState.valid else { return }
            scrollViewState.visibleRect = computeVisibleRect()
            scrollViewState.zoomScale = scrollView.zoomScale
            scrollViewState.invZoomScale = 1.0 / scrollView.zoomScale
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollViewStateChanged()
        }
        
        public func scrollViewDidZoom(_ scrollView: UIScrollView) {
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
        
        func scrollCenter(to position: CGPoint, zoom: CGFloat? = nil, animated: Bool = false) {
            let z = zoom ?? scrollView.zoomScale
            let p = z * position - 0.5 * CGPoint(fromSize: scrollView.bounds.size)
            
            UIView.animate(withDuration: animated ? 0.2 : 0.0) {
                if let zoom = zoom {
                    self.scrollView.zoomScale = zoom
                }
                self.scrollView.contentOffset = p
            }
        }
   }
}
#endif
