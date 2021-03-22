//
//  GUIAlertWatcher.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Combine
import SwiftUI

/// An observable object that a GUI can watch to present app-wide alerts/warnings etc.
///
/// A GUI should gate on current being non-nil to show either a warning or yesOrCancel alert, while gating
/// on popupVisible to show a popup alert.
///
/// Call dismissAlert() to dismiss the current alert (i.e. when the user clicks any of the
/// presented buttons).
///
/// Note that popups are not considered dismissable; they will dismiss themselves (by having popupVisible reset to false)
/// after popupDuration seconds have passed.
public class GUIAlertWatcher : ObservableObject {
    /// Supported alert types.
    public enum AlertType {
        case warning
        case yesOrCancel
    }
    
    public enum PopupType {
        case okPopup
    }
    
    /// A grouping structure for the various attributes of an alert.
    public struct Attributes {
        /// Alert type.
        public var alertType = AlertType.warning
        
        /// Title.
        public var title = ""
        
        /// Optional details.
        public var details: String?
        
        /// Label for primary button (for askYesNo alerts).
        public var yesButtonText = ""
        
        /// Callback for an yesOrCancel alert.
        public var yesOrCancelAction: ((Bool) -> ())? = nil
        
        /// Optional dismissal callback.
        public var onDismissAction: (() ->())? = nil
        
        /// Unique integer ID.  The value below is uniquely associated with
        /// each group of attributes; use it to identify if some future
        /// GUI action is looking at the same set of attributes as when the
        /// operation was initially scheduled.
        public let uniqueID: Int
    }

    /// Construct an alert watcher instance.
    public init() {
    }

    /// The current set of attributes.  If no warning/question should be shown,
    /// then current will be nil.
    public var current: Attributes? { attributesStack.last }

    /// Dismiss the current warning/qustion.  (Do not call this for popups!)
    @discardableResult
    public func dismissCurrent() -> Attributes? {
        objectWillChange.send()
        return attributesStack.popLast()
    }
    
    /// True if a popup should be shown.
    public private(set) var popupVisible = false
    
    /// Popup type.
    public private(set) var popupType = PopupType.okPopup
    
    /// Popup message.
    public private(set) var popupMessage = ""
    
    /// Popup duration
    public private(set) var popupDuration = 2.0

    public private(set) var popupUniqueID = 0

    private var attributesStack = [Attributes]()
    private var uniqueIDCounter = 0
    
    /// Request a warning be displayed.
    /// - Parameters:
    ///   - title: title of warning
    ///   - details: more detailed message
    ///   - onDismiss: callback when alert is dismissed
    public func showWarning(_ title: String, details: String? = nil, onDismiss: (() ->())? = nil) {
        uniqueIDCounter += 1
        attributesStack.append(Attributes(alertType: .warning, title: title,
                                          details: details, onDismissAction: onDismiss,
                                          uniqueID: uniqueIDCounter))
        objectWillChange.send()
    }

    /// Request a warning be displayed.
    /// - Parameters:
    ///   - title: title of warning
    ///   - error: An Error object describing what went wrong
    ///   - onDismiss: callback when alert is dismissed
    public func showWarning(_ title: String, error: Error, onDismiss: (() ->())? = nil) {
        uniqueIDCounter += 1
        attributesStack.append(Attributes(alertType: .warning, title: title,
                                          details: String(describing: error), onDismissAction: onDismiss,
                                          uniqueID: uniqueIDCounter))
        objectWillChange.send()
    }

    
    /// Request a yes/no question be displayed
    /// - Parameters:
    ///   - title: title for question
    ///   - details: more detailed message
    ///   - yesText: label for "yes" button
    ///   - onDismiss: called with true/false when alert is dismissed
    public func yesOrCancel(_ title: String, details: String? = nil, yesText: String,
                            onDismiss: @escaping ((Bool) ->())) {
        uniqueIDCounter += 1
        attributesStack.append(Attributes(alertType: .yesOrCancel, title: title, details: details, yesButtonText: yesText,
                                          yesOrCancelAction: onDismiss, uniqueID: uniqueIDCounter))
        objectWillChange.send()
    }
    
    /// Create a popup which goes away on its own.
    /// - Parameters:
    ///   - title: Short message
    ///   - duration: Duration before fading out
    ///
    /// This function should be used for a general confirmation that
    /// something succeeded.
    public func okPopup(_ title: String, duration: Double = 2.0) {
        popupUniqueID += 1
        popupVisible = true
        popupMessage = title
        popupDuration = duration
        popupType = .okPopup
        
        let popupID = popupUniqueID
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if popupID == self.popupUniqueID {
                self.popupVisible = false
                self.objectWillChange.send()
            }
        }
        objectWillChange.send()
    }
}
