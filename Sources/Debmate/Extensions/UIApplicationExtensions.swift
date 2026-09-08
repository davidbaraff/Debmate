//
//  UIApplicationExtensions.swift
//  Debmate
//
//  Created by David Baraff on 8/9/26.
//

#if os(iOS)

import UIKit

public extension UIApplication {
    /// Returns the root view controller on the device's own screen (excludes any
    /// external/AirPlay display), suitable for anchoring presentations
    /// such as ASWebAuthenticationSession or an OIDC login flow.
    static func topViewController() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .filter({ $0.session.role == .windowApplication })   // exclude external display
                .flatMap({ $0.windows })
                .first(where: \.isKeyWindow)?
                .rootViewController else {
            return nil
        }
        return topViewController(from: root)
    }
    
    /// Returns the key window on the device's own screen (excludes any
    /// external/AirPlay display), suitable for anchoring presentations
    /// such as ASWebAuthenticationSession or an OIDC login flow.
    static func presentationWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowApplication }   // exclude external display
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)
    }
    
    private static func topViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return vc
    }
}

#endif

