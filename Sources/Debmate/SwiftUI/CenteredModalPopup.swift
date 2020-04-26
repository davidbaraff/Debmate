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
    let closeText: String
    let acceptText: String?
    let acceptAction: (() -> ())?
    var popupContent: PopupContent
    var overlayedContent: OverlayedContent
    
    public init(isPresented: Binding<Bool>,
                parentWidthFraction: CGFloat = 0.9,
                closeText: String,
                acceptText: String?, acceptAction: (() ->())?,
                @ViewBuilder popupContent: () -> PopupContent,
                @ViewBuilder overlayedContent: () -> OverlayedContent) {
        self._isPresented = isPresented
        self.parentWidthFraction = parentWidthFraction
        self.closeText = closeText
        self.acceptText = acceptText
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
                if !self.isPresented {
                    return self.overlayedContent.anyView()
                }
                else {
                    return self.overlayedContent.blur(radius: 6).overlay(Color(.displayP3, white: 0.6, opacity: 0.5)).onTapGesture { withAnimation { self.isPresented = false} }.anyView()
                }
            }

            if isPresented {
                VStack {
                    HStack {
                        Button(action: { withAnimation { self.isPresented = false } }) {
                            Text(closeText)
                        }
                        Spacer()
                        if acceptText != nil {
                            Button(action: {
                                self.acceptAction?()
                                self.isPresented = false
                            }) {
                                Text(acceptText ?? "Done")
                            }
                        }
                    }.padding([.top], 8).padding([.leading, .trailing], 12)

                    popupContent.padding([.leading, .trailing, .bottom], 8)
                }.frame(width: parentWidthFraction * parentWidth)
                 .fixedSize().background(Color.white).cornerRadius(12)
            }
        }
    }
}

public extension View {
    /// Displays a centered modal popup.
    /// - Parameters:
    ///   - isPresented: isPresented binding
    ///   - parentWidthFraction: Fraction of the parent width taken by popup
    ///   - closeText: text for the dismiss button
    ///   - acceptText: optional text for an "accept" button
    ///   - acceptAction: optional action taken if the "accept" button is clicked
    ///   - popupContent: The content of the popup to be presented
    /// - Returns: some View
    func centeredModalPopup<PopupContentView : View>(isPresented: Binding<Bool>,
                            parentWidthFraction: CGFloat = 0.9,
                            closeText: String = "Close",
                            acceptText: String? = nil,
                            acceptAction: (() ->())? = nil,
                            @ViewBuilder popupContent: () -> PopupContentView) -> CenteredModalPopupView<Self, PopupContentView> {
        CenteredModalPopupView(isPresented: isPresented, parentWidthFraction: parentWidthFraction,
                               closeText: closeText, acceptText: acceptText, acceptAction: acceptAction,
                               popupContent: popupContent) {
                                self
        }
    }
}
