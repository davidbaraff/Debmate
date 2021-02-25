//
//  AppUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)
import Foundation
import UIKit

fileprivate class ApplicationStateTracker {
    var observer: NSObjectProtocol!
    let notice = Lnotice<Bool>()
    
    init() {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
            self.notice.broadcast(false)
        }

        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            self.notice.broadcast(true)
        }
    }
}

private let stateTracker = ApplicationStateTracker()

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



