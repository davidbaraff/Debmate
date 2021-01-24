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

public class ZoomableScrollViewState : ObservableObject{
    @Published public var zoomScale = CGFloat(1)
    @Published public var invZoomScale = CGFloat(1)
    @Published public var visibleRect = CGRect.zero
}

public protocol ZoomableScrollViewControl {
    func scrollCenter(to location: CGPoint, zoom: CGFloat?, animated: Bool)
}

public extension ZoomableScrollViewControl {
    func scrollCenter(to location: CGPoint, zoom: CGFloat?) {
        scrollCenter(to: location, zoom: zoom, animated: true)
    }
}

#if os(iOS)
public struct ZoomableScrollView<Content : View> : UIViewRepresentable {
    let content: (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content
    let coordinator: Coordinator

    public init(contentSize: CGSize,
         minZoom: CGFloat = 1/250,
         maxZoom: CGFloat = 4,
         @ViewBuilder content: @escaping (ZoomableScrollViewState, ZoomableScrollViewControl) -> Content) {
        self.content = content

        coordinator = Coordinator(contentSize)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            coordinator.scrollCenter(to: coordinator.offset, zoom: 1.0, animated: false)
            coordinator.allowRecenter = true
        }

        return coordinator.scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: UIViewRepresentableContext<ZoomableScrollView>) {
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
    
        public init(_ contentSize: CGSize) {
            self.contentSize = contentSize
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
