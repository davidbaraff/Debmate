//
//  CenteredModalPopup.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import SwiftUI

public struct CenteredModalPopupView<OverlayedContent, PopupContent> : View where OverlayedContent : View, PopupContent : View {
    @Binding var isPresented: Bool
    @State var parentWidth = CGFloat(0)
    let parentWidthFraction: CGFloat
    let backgroundColor: Color
    let shadowColor: Color?
    let closeText: String
    let acceptText: String?
    let titleText: String?
    let acceptAction: (() -> ())?
    var popupContent: PopupContent
    var overlayedContent: OverlayedContent
    @State var blurRadius: Double = 0
    
    public init(isPresented: Binding<Bool>,
                parentWidthFraction: CGFloat = 0.9,
                backgroundColor: Color = Color(.displayP3, white: 0.6, opacity: 0.5),
                shadowColor: Color?,
                closeText: String,
                acceptText: String?,
                titleText: String? = nil,
                acceptAction: (() ->())?,
                @ViewBuilder popupContent: () -> PopupContent,
                @ViewBuilder overlayedContent: () -> OverlayedContent) {
        self._isPresented = isPresented
        self.parentWidthFraction = parentWidthFraction
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
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
                #if os(iOS)
                return self.overlayedContent
                    .blur(radius: isPresented ? blurRadius : 0)
                    .overlay(isPresented ? backgroundColor : .clear)
                    .onTapGesture {
                        if isPresented {
                            withAnimation {
                                self.isPresented = false
                                self.blurRadius = 0
                            }
                        }
                    }.anyView()
                #else
                return self.overlayedContent.blur(radius: blurRadius)
                    .overlay(Color(.displayP3, white: 0.6, opacity: 0.5)).anyView()
                #endif
            }

            if isPresented {
                VStack {
                    HStack {
                        Button(action: { withAnimation { self.isPresented = false } }) {
                            Text(closeText)
                        }
                        Spacer()
                        if let titleText = titleText {
                            Text(titleText)
                            Spacer()
                        }
                        if let acceptText = acceptText {
                            Button(action: {
                                self.acceptAction?()
                                self.isPresented = false
                            }) {
                                Text(acceptText)
                            }
                        }
                    }.padding([.top], 8).padding([.leading, .trailing], 12)

                    popupContent.padding([.leading, .trailing, .bottom], 8)
                }.frame(width: parentWidthFraction * parentWidth)
                 .fixedSize().background(Color.white).cornerRadius(12)
                 .shadow(color: shadowColor ?? .clear, radius: 5, x: 0, y: 0)
                 .onAppear {
                     blurRadius = 6
                 }
            }
        }
    }
}

public extension View {
    /// Displays a centered modal popup.
    /// - Parameters:
    ///   - isPresented: isPresented binding
    ///   - parentWidthFraction: Fraction of the parent width taken by popup
    ///   - backgroundColor: color of full cover bacground over arent
    ///   - shadowColor: shadow color if non-nil
    ///   - closeText: text for the dismiss button
    ///   - titleText: extra information about this popup
    ///   - acceptText: optional text for an "accept" button
    ///   - acceptAction: optional action taken if the "accept" button is clicked
    ///   - popupContent: The content of the popup to be presented
    /// - Returns: some View
    func centeredModalPopup<PopupContentView : View>(isPresented: Binding<Bool>,
                            parentWidthFraction: CGFloat = 0.9,
                            backgroundColor: Color = Color(.displayP3, white: 0.6, opacity: 0.5),
                            shadowColor: Color? = nil,
                            closeText: String = "Close",
                            acceptText: String? = nil,
                            titleText: String? = nil,
                            acceptAction: (() ->())? = nil,
                            @ViewBuilder popupContent: () -> PopupContentView) -> CenteredModalPopupView<Self, PopupContentView> {
        CenteredModalPopupView(isPresented: isPresented, parentWidthFraction: parentWidthFraction,
                               backgroundColor: backgroundColor, shadowColor: shadowColor,
                               closeText: closeText,
                               acceptText: acceptText,
                               titleText: titleText,
                               acceptAction: acceptAction,
                               popupContent: popupContent) {
                                self
        }
    }
}
