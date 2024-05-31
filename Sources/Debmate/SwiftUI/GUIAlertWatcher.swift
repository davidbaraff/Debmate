//
//  GUIAlertWatcher.swift
//  Debmate
//
//  Copyright © 2021 David Baraff. All rights reserved.
//

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
///

@MainActor
public class GUIAlertWatcher : ObservableObject {
    /// Supported alert types.
    public enum AlertType {
        case warning
        case yesOrCancel
        case textEntryOrCancel
        case multipleChoice
    }
    
    /// Supported popup tyypes.
    public enum PopupType {
        case okPopup
        case warningPopup
        case bottomInfoPopup
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
        
        /// Label for dismiss button in a warning alert.
        public var dismissButtonText = "OK"
        
        /// If the action (for askYesNo alerts) needs extra emaphasis.
        public var destructive = false
        
        /// Callback for an yesOrCancel alert.
        public var yesOrCancelAction: ((Bool) -> ())? = nil

        /// Callback for an yesOrCancel alert.
        public var textEntryOrCancelAction: ((String?) -> ())? = nil

        /// Optional dismissal callback.
        public var onDismissAction: (() ->())? = nil
        
        /// Callback/data for a multipleChoice alert
        public var multipleChoiceAction: ((Any) -> ())? = nil

        /// Text and values for a multipleChoice alert
        public var multipleChoiceTextAndValues = [(String, Any)]()

        /// Index of default (i.e. bolded) choice for multiple choice alert
        public var multipleChoiceDefaultIndex = -1

        /// True if the current (non-popup) view should be dismissed.
        public internal(set) var dismissRequested = false

        /// Unique integer ID.  The value below is uniquely associated with
        /// each group of attributes; use it to identify if some future
        /// GUI action is looking at the same set of attributes as when the
        /// operation was initially scheduled.
        public let uniqueID: Int
    }

    /// Construct an alert watcher instance.
    ///
    /// Set compactSize to true for iPhone sized devices.
    public init(compactSize: Bool = false) {
        self.compactSize = compactSize
    }

    let compactSize: Bool

    /// The current set of attributes.  If no warning/question should be shown,
    /// then current will be nil.
    public var current: Attributes? { attributesStack.last }
    
    /// True if a warning/question is currently being shown.
    public var active: Bool { current != nil }

    /// Dismiss the current warning/question.  (Do not call this for popups!)
    ///
    /// When building a View to support this class, use dismissCurrent() to dismiss
    /// the current alert.
    ///
    /// However, to dismiss an alert from outside the view code, users should
    /// never call this routine, but instead call manuallDismissCurrent(), which acts
    /// as if the user had clicked on the dismiss/cancel button.
    @discardableResult
    public func dismissCurrent() -> Attributes? {
        defer { objectWillChange.send() }
        return attributesStack.popLast()
    }
    
    /// Manually dismiss the current warning/question by an outside agent; acts as if the cancel/OK button was clicked.
    /// (For multiple choice cases, calling manuallyDismissCurrent() acts as if the user clicked the first item
    /// in the list of multiple choices.)
    public func manuallyDismissCurrent() {
        guard !attributesStack.isEmpty else { return }
        defer { objectWillChange.send() }
        attributesStack[attributesStack.count-1].dismissRequested = true
    }
    
    /// True if manuallyDismissCurrent() has been called for the top of the attributes stack.
    public var dismissCurrentRequested: Bool { attributesStack.last?.dismissRequested == true }
    
    /// True if a popup should be shown.
    public private(set) var popupVisible = false
    
    /// Popup type.
    public private(set) var popupType = PopupType.okPopup
    
    /// Popup message.
    public private(set) var popupMessage = ""
    
    /// Popup duration
    public private(set) var popupDuration: Double? = 2.0

    public private(set) var popupUniqueID = 0

    /// ID of current dialog shown.
    public var currentIDCounter: Int { uniqueIDCounter }
    
    /// ID Of next dialog shown.
    public var nextIDCounter: Int { uniqueIDCounter + 1 }

    private var attributesStack = [Attributes]()
    private var uniqueIDCounter = 0
    
    /// Request a warning be displayed.
    /// - Parameters:
    ///   - title: title of warning
    ///   - details: more detailed message
    ///   - dismissButtonText: text for dismiss button (default is "OK")
    ///   - onDismiss: callback when alert is dismissed
    public func showWarning(_ title: String, details: String? = nil, dismissButtonText: String = "OK", onDismiss: (() ->())? = nil) {
        uniqueIDCounter += 1
        attributesStack.append(Attributes(alertType: .warning,
                                          title: title,
                                          details: details,
                                          dismissButtonText: dismissButtonText,
                                          onDismissAction: onDismiss,
                                          uniqueID: uniqueIDCounter))
        objectWillChange.send()
    }

    /// Request a warning be displayed.
    /// - Parameters:
    ///   - title: title of warning
    ///   - error: An Error object describing what went wrong
    ///   - dismissButtonText: text for dismiss button (default is "OK")
    ///   - onDismiss: callback when alert is dismissed
    public func showWarning(_ title: String, error: Error, dismissButtonText: String = "OK", onDismiss: (() ->())? = nil) {
        showWarning(title, details: error.localizedDescription, onDismiss: onDismiss)
    }

    /// Async version of showWarning(_ titile: details: dismissButtonText: onDismiss)
    public func showWarning(_ title: String, details: String? = nil, dismissButtonText: String = "OK") async {
        uniqueIDCounter += 1
        objectWillChange.send()
        
        return await withCheckedContinuation { continuation in
            attributesStack.append(Attributes(alertType: .warning,
                                              title: title,
                                              details: details,
                                              dismissButtonText: dismissButtonText,
                                              onDismissAction: { continuation.resume() },
                                              uniqueID: uniqueIDCounter))
        }
    }
    
    /// Async version of showWarning(_ titile: error: dismissButtonText: onDismiss)
    public func showWarning(_ title: String, error: Error, dismissButtonText: String = "OK") async {
        await showWarning(title, details: error.localizedDescription, dismissButtonText: dismissButtonText)
    }

    /// Run code while a dialog blocks the UI, allowing for cancelation.
    ///
    /// Returns the value returned by operation(), run in a task, provided that operation()
    /// completes before the user clicks the "cancel" button in the shown dialog.
    ///
    /// Otherwise, operation() is canceled and nil is returned.
    public func withCancelation<T>(_ title: String, details: String? = nil, operation: @Sendable @escaping () async -> T) async -> T? {
        var result: T?
        var alertDismissed = true
        
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask { @MainActor in
                try? await Task.sleep(seconds: 0.25)
                guard result == nil else {
                    return
                }

                alertDismissed = false
                await self.showWarning(title, details: details, dismissButtonText: "Cancel")
                alertDismissed = true
            }
            
            taskGroup.addTask {
                let r = await operation()
                await MainActor.run {
                    result = r
                }
            }
            
            await taskGroup.next()
            taskGroup.cancelAll()

            /*
             * Who is done with what?
             */

            if !alertDismissed {
                try? await Task.sleep(seconds: 0.25)
                manuallyDismissCurrent()
            }
        }
        
        return result
    }

    /// Request a yes/no question be displayed
    /// - Parameters:
    ///   - title: title for question
    ///   - details: more detailed message
    ///   - yesText: label for "yes" button
    ///   - destructive: if true, adds extra emphasis to the yes button
    ///   - onDismiss: called with true/false when alert is dismissed
    public func yesOrCancel(_ title: String, details: String? = nil, yesText: String,
                            destructive: Bool = false,
                            onDismiss: @escaping ((Bool) ->())) {
        uniqueIDCounter += 1
        attributesStack.append(Attributes(alertType: .yesOrCancel, title: title, details: details, yesButtonText: yesText,
                                          destructive: destructive,
                                          yesOrCancelAction: onDismiss, uniqueID: uniqueIDCounter))

        objectWillChange.send()
    }

    /// Async version of yesOrCancel(_ title: details:  yesText: destructive)
    public func yesOrCancel(_ title: String, details: String? = nil, yesText: String,
                            destructive: Bool = false) async -> Bool {
        uniqueIDCounter += 1
        objectWillChange.send()
        
        return await withCheckedContinuation { continuation in
            attributesStack.append(Attributes(alertType: .yesOrCancel,
                                              title: title,
                                              details: details,
                                              yesButtonText: yesText,
                                              destructive: destructive,
                                              yesOrCancelAction: { continuation.resume(returning: $0) },
                                              uniqueID: uniqueIDCounter))
        }
    }
    
    /// Request a text entry field be displayed in an alert dialog.
    /// - Parameters:
    ///   - title: title for alert
    ///   - details: more detailed message
    ///   - acceptText: label for accept button
    ///   - destructive: if true, adds extra emphasis to the aceppt button
    ///
    /// If the user hits accept, a string with the contents of the text field is filled in.
    /// Otherwise, nil is returned.
    public func textEntryOrCancel(_ title: String, details: String? = nil, acceptText: String) async -> String? {
        uniqueIDCounter += 1
        objectWillChange.send()
        
        return await withCheckedContinuation { continuation in
            attributesStack.append(Attributes(alertType: .textEntryOrCancel,
                                              title: title,
                                              details: details,
                                              yesButtonText: acceptText,
                                              destructive: false,
                                              textEntryOrCancelAction: { continuation.resume(returning: $0) },
                                              uniqueID: uniqueIDCounter))
        }
    }
    
    /// Show an alert dialog with an arbitrary number of multiple return values.
    /// - Parameters:
    ///   - title: title for alert
    ///   - details: more detailed message
    ///   - choices: an array of tuples of labels and possible return values
    ///   - defaultIndex: index of choice to be displayed as the default choice
    /// The value of the item the user selects is returned.
    public func showMultipleChoiceAlert<T>(_ title: String, details: String? = nil,
                                           choices: [(String, T)],
                                           defaultIndex: Int = -1) async -> T {
        uniqueIDCounter += 1
        objectWillChange.send()
        
        return await withCheckedContinuation { continuation in
            attributesStack.append(Attributes(alertType: .multipleChoice,
                                              title: title,
                                              details: details,
                                              multipleChoiceAction: { continuation.resume(returning: $0 as! T) },
                                              multipleChoiceTextAndValues: choices.map { ($0.0, $0.1) },
                                              multipleChoiceDefaultIndex: defaultIndex,
                                              uniqueID: uniqueIDCounter))
        }
    }
    
    /// Create a popup which goes away on its own.
    /// - Parameters:
    ///   - title: Short message
    ///   - duration: Duration before fading out
    ///
    /// This function should be used for a general confirmation that
    /// something succeeded.
    public func okPopup(_ title: String, duration: Double = 2.0) {
        showPopup(.okPopup, title, duration)
    }

    /// Create a warning popup.
    /// - Parameters:
    ///   - title: Short message
    ///   - duration: Duration before fading out
    ///
    /// This function should be used for non-modal warning that doesn't require a response.
    public func warningPopup(_ title: String, duration: Double? = 2.0) {
        showPopup(.warningPopup, title, duration)
    }
    
    /// Create a popup which goes away on its own.
    /// - Parameters:
    ///   - title: Short message
    ///   - duration: Duration before fading out
    ///
    /// This function should be used for a general confirmation that
    /// something happened, in a low-keyish sort of way.
    public func bottomInfoPopup(_ title: String, duration: Double = 2.0) {
        showPopup(.bottomInfoPopup, title, duration)
    }
    
    @available(iOS 17, macOS 17, tvOS 17, *)
    public func view(for current: Attributes) -> some View {
        switch current.alertType {
        case .warning:
            return WarningView(title: current.title, message: current.details ?? "",
                               actionName: nil,
                               dismissName: current.dismissButtonText,
                               onAction: { self.dismissCurrent() },
                               onDismiss: {
                                    self.dismissCurrent()
                                    current.onDismissAction?()
                               }, destructive: false).id(current.uniqueID).anyView()
        case .yesOrCancel:
            return WarningView(title: current.title,
                               message: current.details ?? "",
                               actionName: current.yesButtonText,
                               dismissName: "Cancel",
                               onAction: {
                                    self.dismissCurrent()
                                    current.yesOrCancelAction?(true)
                               },
                               onDismiss: {
                                    current.yesOrCancelAction?(false)
                                    self.dismissCurrent()
                               },
                               destructive: current.destructive).id(current.uniqueID).anyView()
        case .textEntryOrCancel:
            return WarningView(title: current.title,
                               message: current.details ?? "",
                               actionName: current.yesButtonText,
                               dismissName: "Cancel",
                               onAction: {
                                    self.dismissCurrent()
                               },
                               onDismiss: {
                                    self.dismissCurrent()
                               },
                               destructive: current.destructive,
                               textEntryOrCancelAction: current.textEntryOrCancelAction).id(current.uniqueID).anyView()
        case .multipleChoice:
            return MultipleChoiceAlertView(title: current.title,
                                           labelsAndValues: current.multipleChoiceTextAndValues,
                                           defaultIndex: current.multipleChoiceDefaultIndex,
                                           message: current.details ?? "",
                                           onChoice: {
                                                self.dismissCurrent()
                                                current.multipleChoiceAction?($0)
            }).id(current.uniqueID).anyView()
        }
    }
    
    
    /// Hides any popup currently visible.
    public func hidePopup() {
        popupUniqueID += 1
        if popupVisible {
            popupDuration = 0.0
            objectWillChange.send()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                popupVisible = false
                objectWillChange.send()
            }
        }
    }
    
    private func showPopup(_ type: PopupType, _ title: String, _ duration: Double?) {
        popupUniqueID += 1
        popupVisible = true
        popupMessage = title
        popupDuration = duration
        popupType = type
        
        let popupID = popupUniqueID
        if let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if popupID == self.popupUniqueID {
                    self.popupVisible = false
                    self.objectWillChange.send()
                }
            }
        }
        objectWillChange.send()
    }
}
