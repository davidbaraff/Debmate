//
//  AppUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)
import Foundation
import UIKit

@MainActor
fileprivate final class ApplicationStateTracker {
    var observer: NSObjectProtocol!
    let notice = Lnotice<Bool>()
    
    init() {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                self.notice.broadcast(false)
            }
        }

        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                self.notice.broadcast(true)
            }
        }
    }
}

@MainActor private let stateTracker = ApplicationStateTracker()

@MainActor
extension Util {
    static public var applicationForegroundChangeNotice: Lnotice<Bool> {
        stateTracker.notice
    }
    
    static public var applicationIsInForeground: Bool {
        return UIApplication.shared.applicationState != .background
    }
    
    static public func applicationUniqueID(applicationName: String) -> String? {
        if let id = UIDevice.current.identifierForVendor {
            return "\(applicationName)(\(id.uuidString.prefix(8)))"
        }
        return nil
    }
}
#else
extension Util {
    static public func applicationUniqueID(applicationName: String) -> String? {
        return nil
    }
}
#endif



