//
//  GUIAlertViews.swift
//  Debmate
//
//  Created by David Baraff on 4/5/24.
//

#if !os(watchOS)

import Foundation
import SwiftUI

#if os(macOS)
public typealias UIKeyboardType = Void
#endif

@available(iOS 17, macOS 17, tvOS 17, *)
public struct WarningView : View {
    @EnvironmentObject var guiAlertWatcher: GUIAlertWatcher
    @Environment(\.colorScheme) var colorScheme
    var coveringViewColor: Color {
        colorScheme == .light ? Color(white: 0.3, opacity: 0.3) : Color.black.opacity(0.3)
    }
    
    var maxDeviceHeight: CGFloat? {
        #if !os(macOS)
        return UIDevice.current.orientation.isLandscape ? 300 * overallScale / 100  : nil
        #else
        return nil
        #endif
    }

    @ScaledMetric var spacing = 10
    @ScaledMetric var buttonHeight = 55

    @ScaledMetric var overallScale = 100
    var alertWidth: Double { (guiAlertWatcher.compactSize ? 300 : 450) * overallScale / 100 }
    var alertHeight: Double { (guiAlertWatcher.compactSize ? 150 : 200) * overallScale / 100 }
    var alertMaxHeight: CGFloat? { guiAlertWatcher.compactSize ? maxDeviceHeight : nil }

    @FocusState private var focus: Bool

    let title: String
    let message: String
    let actionName: String?
    let dismissName: String
    let onAction: (() -> ())
    let onDismiss: (() -> ())
    let destructive: Bool
    let textEntryOrCancelAction: ((String?) -> ())?
    let keyboardType: UIKeyboardType?
    
    @State var textValue = ""
    
    @State var alreadyDismissed = false
    @State var opacity = 0.0
    
    public init(title: String, message: String, actionName: String? = nil, dismissName: String,
                onAction: @escaping (() -> ()), onDismiss: @escaping (() -> ()),
                destructive: Bool,
                keyboardType: UIKeyboardType?,
                textEntryOrCancelAction: ((String?) ->())? = nil) {
        self.title = title
        self.message = message
        self.actionName = actionName
        self.dismissName = dismissName
        self.onAction = onAction
        self.onDismiss = onDismiss
        self.destructive = destructive
        self.keyboardType = keyboardType
        self.textEntryOrCancelAction = textEntryOrCancelAction
    }
    
    func dismiss(cancel: Bool) {
        guard !alreadyDismissed else { return }
        alreadyDismissed = true
        
        withAnimation(.linear(duration: 0.2)) {
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if cancel {
                onDismiss()
                textEntryOrCancelAction?(nil)
            }
            else {
                onAction()
                textEntryOrCancelAction?(textValue)
            }
        }
    }

    public var body : some View {
        ZStack {
            coveringViewColor.opacity(opacity).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: spacing) {
                Text(title).font(.title2).fontWeight(.semibold).padding().fixedSize()
                
                if textEntryOrCancelAction != nil {
                    TextField("", text: $textValue).textFieldStyle(.roundedBorder)
                        #if !os(macOS)
                        .keyboardType(keyboardType ?? .default)
                        #endif
                        .focused($focus)
                        .padding()
                        .onAppear {
                            focus = true
                        }
                }

                Text(message)
                    .lineLimit(15)
                    .multilineTextAlignment(.leading)
                    .font(Font.body)
                    .padding()
                
                Divider()
                
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                dismiss(cancel: true)
                            }) {
                                Text(dismissName).bold().offset(x: 0, y: -5)
                            }
                            Spacer()
                        }
                        
                        if let actionName = actionName {
                            Divider()
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    dismiss(cancel: false)
                                }) {
                                    if destructive {
                                        Text(actionName).foregroundColor(.red)
                                    }
                                    else {
                                        Text(actionName)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }.frame(height: buttonHeight)
                
            }.frame(width: alertWidth)
             .frame(minHeight: alertHeight, maxHeight: alertMaxHeight)
             .background(Color.systemBackground)
             .cornerRadius(12)
             .fixedSize()
             .opacity(opacity)
             .onChange(of: guiAlertWatcher.dismissCurrentRequested) {
                 dismiss(cancel: true)
             }
             .onAppear {
                 textValue = ""
                  withAnimation(.linear(duration: 0.2)) {
                      opacity = 1
                  }
             }
        }
    }
}

@available(iOS 17, macOS 17, tvOS 17, *)
public struct MultipleChoiceAlertView : View {
    @EnvironmentObject var guiAlertWatcher: GUIAlertWatcher
    @Environment(\.colorScheme) var colorScheme
    var coveringViewColor: Color {
        colorScheme == .light ? Color(white: 0.3, opacity: 0.3) : Color.black.opacity(0.3)
    }

    @ScaledMetric var spacing = 10
    @ScaledMetric var buttonHeight = 55

    @ScaledMetric var overallScale = 100
    var alertWidth: Double { (guiAlertWatcher.compactSize ? 300 : 450) * overallScale / 100 }
    var alertHeight: Double { (guiAlertWatcher.compactSize ? 150 : 200) * overallScale / 100 }
    
    let title: String
    let labelsAndValues: [(String, Any)]
    let defaultIndex: Int
    let message: String
    let onChoice: ((Any) -> ())

    public init(title: String, labelsAndValues: [(String, Any)], defaultIndex: Int,
                message: String, onChoice: @escaping ((Any) -> ())) {
        self.title = title
        self.labelsAndValues = labelsAndValues
        self.defaultIndex = defaultIndex
        self.message = message
        self.onChoice = onChoice
    }

    @State var alreadyDismissed = false
    @State var opacity = 0.0
    
    func dismiss(value: Any) {
        guard !alreadyDismissed else { return }
        alreadyDismissed = true
        
        withAnimation(.linear(duration: 0.2)) {
            opacity = 0
        }

        Task {
            try await Task.sleep(seconds: 0.2)
            onChoice(value)
        }
    }

    public var body : some View {
        ZStack {
            coveringViewColor.opacity(opacity).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: spacing) {
                Text(title).font(.title2).fontWeight(.semibold).padding().fixedSize()
                
                Text(message)
                    .lineLimit(15)
                    .multilineTextAlignment(.leading)
                    .font(Font.body)
                    .padding()
                
                // Divider()
                
                VStack(spacing: 0) {
                    ForEach(labelsAndValues.enumeratedArray(), id: \.1.0) { (index, labelAndValue) in
                        Button(action: { dismiss(value: labelAndValue.1) }) {
                            VStack {
                                Divider()
                                Spacer()
                                Text(labelAndValue.0)
                                Spacer()
                            }.frame(height: buttonHeight)
                        }.keyboardShortcut(index == defaultIndex ? .defaultAction : .none)
                    }
                }
                
            }.frame(width: alertWidth)
             .frame(minHeight: alertHeight)
             .background(Color.systemBackground)
             .cornerRadius(12)
             .fixedSize()
             .opacity(opacity)
             .onChange(of: guiAlertWatcher.dismissCurrentRequested) {
                 dismiss(value: labelsAndValues[0].1)
             }
             .onAppear {
                  withAnimation(.linear(duration: 0.2)) {
                      opacity = 1
                  }
             }
        }
    }
}

@available(iOS 17, macOS 17, tvOS 17, *)
struct GUIAlertWatcherPopupView: View {
    @State var opacity = 0.0
    @State var counter = 0
    let message: String
    let duration: Double?
    let popupType: GUIAlertWatcher.PopupType
    let uniqueID: Int

    var backgroundColor: Color {
        switch popupType {
        case .okPopup:
            return Self.okColor
        case .warningPopup:
            return Self.warningColor
        case .bottomInfoPopup:
            return Self.bottomInfoColor
        }
    }

    static let bottomInfoColor = Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 0.75)
    static let warningColor = Color(red: 0.6, green: 0.6, blue: 0.1, opacity: 0.85)
    static let okColor = Color(red: 0.1, green: 0.6, blue: 0.1, opacity: 0.75)

    var body: some View {
        VStack {
            if popupType == .bottomInfoPopup {
                Spacer()
            }
            VStack (alignment: .center, spacing: 20) {
                if popupType == .okPopup {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 40, weight: .regular))
                        .padding(EdgeInsets(top: 20, leading: 5, bottom: 5, trailing: 5))
                }
                Text(message).multilineTextAlignment(.center)
                    .frame(maxWidth: 180)
                    .foregroundColor(.white.opacity(popupType == .bottomInfoPopup ? 0.6 : 1))
                    .font(.title3)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10))
            }.frame(width: 200, height: popupType == .bottomInfoPopup ? 50 : 200)
                .background(backgroundColor)
                .cornerRadius(12)
                .opacity(opacity)
                .onTapGesture {
                    withAnimation(.linear(duration: 0.2)) {
                        opacity = 0
                    }
                }
            if popupType == .bottomInfoPopup {
                Spacer().frame(height: 25)
            }
        }
        .onAppear {
            withAnimation {
                opacity = 1
            }
            let id = uniqueID
            if let duration = duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + max(duration - 0.5, 0)) {
                    if id == uniqueID {
                        withAnimation {
                            opacity = 0.0
                        }
                    }
                }
            }
        }
    }
}


@available(iOS 17, macOS 17, tvOS 17, *)
public struct GUIAlertWatcherView<Content> : View where Content : View {
    var content: Content
    @EnvironmentObject var guiAlertWatcher: GUIAlertWatcher

    public init( @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            content
            
            if let current = guiAlertWatcher.current {
                guiAlertWatcher.view(for: current)
            }
            
            if guiAlertWatcher.popupVisible {
                GUIAlertWatcherPopupView(message: guiAlertWatcher.popupMessage,
                                         duration: guiAlertWatcher.popupDuration,
                                         popupType: guiAlertWatcher.popupType,
                                         uniqueID: guiAlertWatcher.popupUniqueID)
                .id(guiAlertWatcher.popupUniqueID)
            }
        }
    }
}

@available(iOS 17, macOS 17, tvOS 17, *)
extension View {
    public func addGUIAlertWatcher() -> GUIAlertWatcherView<Self> {
        GUIAlertWatcherView {
            self
        }
    }
}

#endif

