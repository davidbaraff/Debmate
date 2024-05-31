//
//  UserDefaultsSettingsWatcher.swift
//  Debmate
//
//  Created by David Baraff on 5/9/24.
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Helper class to watch changes to UserDefaults.
public class UserDefaultsSettingsWatcher: NSObject, UNUserNotificationCenterDelegate {
    private var watchedPaths = [String : (String) -> ()]()
    
    /// Watch a keypath in UserDefaults.standard for changes.
    /// - Parameters:
    ///   - keyPath: keyPath being watched
    ///   - initial: if true, the onChange callback is invoked immediately
    ///   - onChange: callback invoked when the default value changes
    public func watchKeyPath(_ keyPath: String, initial: Bool = false, onChange: @escaping (String) -> ()) {
        let add = watchedPaths[keyPath] == nil
        watchedPaths[keyPath] = onChange

        if add {
            UserDefaults.standard.addObserver(self, forKeyPath: keyPath, options: initial ? [.new, .initial] : [.new], context: nil)
        }
    }
    
    /// Do not invoke this function yourself:
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            watchedPaths[keyPath]?(keyPath)
        }
    }
}
