//
//  BatchedUpdatingTextField.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import SwiftUI

public struct BatchedUpdatingTextField: View {
    let placeHolder: String
    @Binding var text: String
    @State var curValue = ""

    public init(_ placeHolder: String, text: Binding<String>) {
        self.placeHolder = placeHolder
        _text = text
        _curValue = State(initialValue: text.wrappedValue)
    }
    
    public var body: some View {
        TextField(placeHolder, text: $curValue,
                  onEditingChanged: { (changed) in
                    if self.text != self.curValue {
                        self.text = self.curValue
                    }
        },
                  onCommit: {
                    if self.text != self.curValue {
                        self.text = self.curValue
                    }
        })
    }
}
