//
//  CustomizableAlert.swift
//  Debmate
//
//  Copyright © 2024 David Baraff. All rights reserved.
//

import SwiftUI

public struct CustomizableAlertPopupView<OverlayedContent, PopupContent> : View where OverlayedContent : View, PopupContent : View {
    @Binding var isPresented: Bool
    @State var parentWidth = CGFloat(0)
    let parentWidthFraction: CGFloat
    let closeText: String
    let acceptText: String?
    let titleText: String?
    let acceptAction: (() -> ())?
    var popupContent: PopupContent
    var overlayedContent: OverlayedContent
    @State var blurRadius: Double = 0
    
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .light ?
        Color(.displayP3, white: 0.6, opacity: 0.5) :
           Color(.displayP3, white: 0.0, opacity: 0.5)
    }

    var popupBackgroundColor: Color {
        colorScheme == .light ?
            Color.systemBackground : Color(.displayP3, white: 0.15)
    }

    public init(isPresented: Binding<Bool>,
                parentWidthFraction: CGFloat = 0.9,
                closeText: String,
                acceptText: String?,
                titleText: String? = nil,
                acceptAction: (() ->())?,
                @ViewBuilder popupContent: () -> PopupContent,
                @ViewBuilder overlayedContent: () -> OverlayedContent) {
        self._isPresented = isPresented
        self.parentWidthFraction = parentWidthFraction
        self.closeText = closeText
        self.acceptText = acceptText
        self.titleText = titleText
        self.acceptAction = acceptAction
        self.overlayedContent = overlayedContent()
        self.popupContent = popupContent()
    }

    public var body: some View {
        ZStack {
            GeometryReader { proxy -> AnyView in
                DispatchQueue.main.async {
                    self.parentWidth = proxy.size.width
                }
                return self.overlayedContent.disabled(isPresented)
                    .overlay(isPresented ? backgroundColor : .clear)
                    .ignoresSafeArea()
                    .anyView()
            }

            if isPresented {
                VStack(spacing: 0) {
                    if let titleText = titleText {
                        HStack {
                            Spacer()
                            Text(titleText).font(.title3).bold()
                            Spacer()
                        }.padding([.top], 8).padding([.leading, .trailing], 12)

                        Spacer().frame(height: 10)
                    }

                    popupContent.padding([.leading, .trailing, .bottom], 8)
                    Spacer().frame(height: 20)

                    Divider().frame(height: 0.5).overlay(Color.primary).opacity(0.25)

                    HStack {
                        if !closeText.isEmpty {
                            Spacer()
                            
                            Button(action: { withAnimation { self.isPresented = false } }) {
                                Text(closeText).font(.title3)
                            }.padding([.top, .bottom], 20)
                            
                            Spacer()
                        }
                        
                        if let acceptText = acceptText {
                            if !closeText.isEmpty {
                                Divider().frame(width: 0.5).overlay(Color.primary).opacity(0.25)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                self.acceptAction?()
                                self.isPresented = false
                            }) {
                                Text(acceptText).font(.title3)
                            }.padding([.top, .bottom], 20)
                            
                            Spacer()
                        }
                    }
                }.frame(width: parentWidthFraction * parentWidth)
                 .fixedSize().background(popupBackgroundColor).cornerRadius(12)
            }
        }
    }
}

public extension View {
    /// Displays a centered modal popup.
    /// - Parameters:
    ///   - isPresented: isPresented binding
    ///   - closeText: text for the dismiss button
    ///   - titleText: extra information about this popup
    ///   - acceptText: optional text for an "accept" button
    ///   - acceptAction: optional action taken if the "accept" button is clicked
    ///   - popupContent: The content of the popup to be presented
    /// - Returns: some View
    func customizableAlert<PopupContentView : View>(_ titleText: String? = nil,
                                                    isPresented: Binding<Bool>,
                                                    closeText: String = "Close",
                                                    acceptText: String? = nil,
                                                    acceptAction: (() ->())? = nil,
                                                    @ViewBuilder popupContent: () -> PopupContentView) -> CustomizableAlertPopupView<Self, PopupContentView> {
        CustomizableAlertPopupView(isPresented: isPresented, parentWidthFraction: 0.85,
                                   closeText: closeText,
                                   acceptText: acceptText,
                                   titleText: titleText,
                                   acceptAction: acceptAction,
                                   popupContent: popupContent) {
            self
        }
    }
}
