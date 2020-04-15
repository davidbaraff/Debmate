//
//  AppUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

#if os(iOS)
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
}

#endif


