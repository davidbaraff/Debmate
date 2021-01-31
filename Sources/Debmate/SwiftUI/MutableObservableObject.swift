//
//  MutableObservableObject.swift
//  Debmate
//
//  Created by David Baraff on 1/24/21.
//

import Combine


/// An ObservableObject holding a mutable ObservableObject.
///
/// This class is useful for SwifftUI Views that need to hold an ObservableObject that might be
/// received via a callback.  Changes to the held observable object are bridged to the MutableObserverObject
/// instance itself.
public class MutableObservableObject<T: ObservableObject> : ObservableObject {
    private var object: T?
    private var cancellable: Cancellable?

    
    /// Initialize this instance to  hold an observable object or nil.
    /// - Parameter object: new obejct to be held
    public init(_ object: T? = nil) {
        self.object = nil
        if let object = object {
            update(object)
        }
    }

    /// Retrieve the held observable object (if any).
    /// - Returns: The held object or nil.
    public func callAsFunction() -> T? {
        object
    }
    
    /// Set a new observable obejct to be held.
    /// - Parameter object: new object to be held.
    public func update(_ object: T) {
        if self.object !== object {
            self.object = object
            cancellable?.cancel()
            cancellable = object.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
}
