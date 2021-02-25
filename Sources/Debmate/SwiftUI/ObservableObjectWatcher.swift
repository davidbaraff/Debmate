//
//  ObservableObjectWatcher.swift
//  Debmate
//
//  Created by David Baraff on 1/24/21.
//

import SwiftUI
import Combine


/// Run a callback when an observable object changed.
///
/// Usage:
///
///     Hstack {
///          ObservableObjectWatcher(someObservableObject, onChange: { _ in ... })
///          Text("...")
///     }
///
///  This construct is useful when an observable object is received, typically in a view buidler
///  callback, and there is no good opportunity to store the object.  The constructed view stores
///  the object and watches it for changes, running the callback as the value is updated.
///  The observable object is passed to the onChange callback as a convenience.
public struct ObservableObjectWatcher<T : ObservableObject> : View {
    @ObservedObject var observed: T
    let onChange: (T) -> ()

    public init(observed: T, onChange: @escaping (T) ->()) {
        self.observed = observed
        self.onChange = onChange
    }

    public var body: some View {
        onChange(observed)

        // must erase to stop view from being elided completely
        return Group { }.anyView()
    }
}

public class FutureObservable<T> : ObservableObject {
    public private(set) var  hasUpdated = false

    public var currentValue: T {
        didSet {
            objectWillChange.send()
            hasUpdated = true
        }
    }
    
    public init(placeholderValue: T) {
        currentValue = placeholderValue
    }
}

public class PublisherWatcher<T> : ObservableObject {
    private var cancellable: Cancellable?
    public var currentValue: T
    
    public init(publisher: AnyPublisher<T, Never>, initialValue: T) {
        self.currentValue = initialValue
        self.cancellable = publisher.receiveOnMain().sink { [weak self] in
            self?.currentValue = $0
            self?.objectWillChange.send()
        }
    }
}


/*
 class Watcher<T> : ObservableObject {
     var value: T!
     var cancellable: Cancellable!
 }

struct PublishedWatcher<T, Content : View>: View {
    @ObservedObject var watcher = Watcher<T>()
    let debugName: String
    let content: (T) -> Content

    init(_ publisher: Published<T>.Publisher, debugName: String, @ViewBuilder content: @escaping (T) -> Content) {
        self.debugName = debugName
        self.content = content

        watcher.cancellable = publisher.sink { [watcher, debugName] in
            print("Value \(debugName) changed to", $0)
            watcher.value = $0
            watcher.objectWillChange.send()
        }
    }

    var body: some View {
        content(watcher.value)
    }
}
 
  let dataXY = someObservableDataObject();
 
 PublishedWatcher(dataXY.$x, debugName: "x") {
     Text("X: \($0)")
     Text("Iter: \(nextCtr())")
 }

*/

