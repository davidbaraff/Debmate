//
//  AskYesNoView.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import SwiftUI

func debugView() -> String {
    print("Debug view fires at \(Date())")
    return ""
}
public struct AskYesNoAlertView<Content> : View where Content : View {
    @Binding var isPresented: Bool
    var autoConfirm: Bool
    let action: () -> ()
    let title: String
    let message: String?
    let yesText: String
    var content: Content
    
    public init(isPresented: Binding<Bool>, autoConfirm: Bool,
                action: @escaping () -> (),
                title: String,
                message: String?,
                yesText: String,
                @ViewBuilder content: () -> Content) {
        _isPresented = isPresented
        self.autoConfirm = autoConfirm
        self.action = action
        self.title = title
        self.message = message
        self.yesText = yesText
        self.content = content()
    }
    
    func runIfAutoconfirm() -> Bool {
        if autoConfirm {
            if isPresented {
                DispatchQueue.main.async {
                    self.action()
                    self.isPresented = false
                }
            }
            return true
        }
        return false
    }
    
    public var body: some View {
        ZStack {
            if runIfAutoconfirm() {
                content
            }
            else {
                content.alert(isPresented: self._isPresented) {
                    Alert(title: Text(title),
                          message: Text(message ?? ""),
                          primaryButton: .default(Text(yesText)) { self.action() },
                          secondaryButton: .cancel())
                }

                /*
                 content.customizableAlert(title,
                 isPresented: self._isPresented,
                 closeText: "Cancel",
                 acceptText: yesText,
                 acceptAction: self.action) {
                 Text(message ?? "")
                 }*/
            }
        }
    }
}

public extension View {
    /// Present a model "yes/no" alert dialog.
    /// - Parameters:
    ///   - isPresented: isPresented binding
    ///   - title: Title for alert
    ///   - message: optional message
    ///   - yesText: text for respoding "yes"
    ///   - noText: text for responding "no"
    ///   - autoConfirm: if true, acts as if yes was immediately chosen, does not display dialog
    ///   - action: action if yes button is clicked
    /// - Returns: some View.
    func askYesNo(isPresented: Binding<Bool>, title: String, message: String?,
                  yesText: String, noText: String = "Cancel", autoConfirm: Bool = false,
                  action: @escaping () -> ()) -> AskYesNoAlertView<Self> {
       AskYesNoAlertView(isPresented: isPresented,
                          autoConfirm: autoConfirm,
                          action: action,
                          title: title,
                          message: message,
                          yesText: yesText) {
                            self
        }
    }
}

