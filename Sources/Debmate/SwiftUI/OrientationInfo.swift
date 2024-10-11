//
//  OrientationInfo.swift
//  Debmate
//
//  Created by David Baraff on 5/14/24.
//

@preconcurrency import Foundation
import SwiftUI

#if os(iOS)

@available(iOS 17, macOS 17, tvOS 17, *)
@Observable
@MainActor
final public class OrientationInfo {
    public enum Orientation {
        case portrait
        case landscape
    }
    
    public private(set) var orientation: Orientation
    
    @ObservationIgnored private var observer: NSObjectProtocol?
    
    public init() {
        // fairly arbitrary starting value for 'flat' orientations
        orientation = UIDevice.current.orientation.isLandscape ? .landscape : .portrait
        
        // unowned self because we unregister before self becomes invalid
        observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
            guard let device = note.object as? UIDevice else {
                return
            }

            Task { @MainActor in
                self.orientation = (device.orientation == .landscapeLeft || device.orientation == .landscapeRight) ?
                    .landscape : .portrait
            }
        }
    }
        
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

#endif

