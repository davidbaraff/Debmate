//
//  DataFlowDebugger.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import SwiftUI

fileprivate  var ctr = 0

fileprivate func nextCtr() -> Int {
    ctr += 1
    return ctr
}

public struct BindingDebuggerView<T> : View {
    let title: String
    @Binding var binding: T
    
    public init(title: String, binding: Binding<T>) {
        self.title = title
        self._binding = binding
    }
    
    public var body: some View {
        Text("\(title): \(nextCtr())")
    }
}

public struct ObservedObjectDebuggerView<T : ObservableObject> : View {
    let title: String
    @ObservedObject var observedObject: T
    
    public init(title: String, observedObject: T) {
        self.title = title
        self.observedObject = observedObject
    }
    
    public var body: some View {
        Text("\(title): \(nextCtr())")
    }
}

public struct LifetimeDebuggerView : View {
    let title: String
    
    public init(title: String) {
        self.title = title
    }
    
    public var body: some View {
        Text("\(title): \(nextCtr())")
    }
}
