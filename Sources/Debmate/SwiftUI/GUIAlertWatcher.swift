//
//  GUIAlertWatcher.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

import Combine

/// An observable object that a GUI can watch to present app-wide alerts/warnings etc.
public class GUIAlertWatcher : ObservableObject {
    /// Supported alert types.
    public enum AlertType {
        case warning
        case yesOrCancel
    }
    
    /// Construct an alert watcher instance.
    public init() {
        
    }

    /// True if alert should be shown.
    @Published public var visible = false

    
    /// Alert type.
    public private(set) var type = AlertType.warning

    /// Title.
    public private(set) var title = ""

    /// Optional message.
    public private(set) var message: String?

    
    /// Label for primary button (for askYesNo alerts).
    public private(set) var yesButtonText = ""

    
    /// Callback for an yesOrCancel alert.
    public private(set) var yesOrCancelAction: ((Bool) -> ())?

    
    /// Optional dismissal callback.
    public private(set) var onDismiss: (() ->())?
    
    
    /// Request a warning be displayed.
    /// - Parameters:
    ///   - title: title of warning
    ///   - message: more detailed message
    ///   - onDismiss: callback when alert is dismissed
    public func showWarning(title: String, message: String? = nil, onDismiss: (() ->())? = nil) {
        visible = true
        self.title = title
        self.message = message
        self.type = .warning
        self.onDismiss = onDismiss
    }
    
    
    /// Request a yes/no question be displayed
    /// - Parameters:
    ///   - title: title for question
    ///   - message: more detailed message
    ///   - yesText: label for "yes" button
    ///   - onDismiss: called with true/false when alert is dismissed
    public func yesOrCancel(title: String, message: String?,
                            yesText: String,
                            onDismiss: @escaping ((Bool) ->())) {
        visible = true
        self.title = title
        self.message = message
        yesButtonText = yesText
        self.type = .yesOrCancel
        self.yesOrCancelAction = onDismiss
    }
}
