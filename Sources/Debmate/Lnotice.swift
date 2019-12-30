//
//  Lnotice.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import Combine

/// Class for holding a set of LnoticeKey<T> objects.
///
/// Use an LnoticeKeySet to hold onto a collection of LnoticeKey objects.
/// To stop listening to all the notice keys and empty the set, call
/// cancelAllAndClear().
public class LnoticeKeySet {
    public init() {
    }
    
    /// Add a new key into the set.
    ///
    /// - Parameter lnoticeKey: An LnoticeKey object being listened to.
    public func add<T>(_ lnoticeKey: LnoticeKey<T>) {
        keys.append(lnoticeKey)
    }
    
    /// Calls cancel() on each key, and discards the keys from the set.
    public func cancelAllAndClear() {
        keys.forEach { $0.cancel() }
        keys = []
    }
    
    public var isEmpty: Bool {
        return keys.isEmpty
    }
    
    private var keys = [Cancellable]()
}

///
/// Object conforming to Cancellable returned from `Lnotice<T>.listen()`.
///
/// As with any Cancellable object, the return instance must be retained
/// as long as the subscription is meant to remain active.
///
public class LnoticeKey<T> : Cancellable {
    fileprivate let receiveValue: ((T) -> ())
    fileprivate let cancellable: AnyCancellable
    
    fileprivate init(cancellable c: AnyCancellable, receiveValue r: @escaping (T ) -> ()) {
        cancellable = c
        receiveValue = r
    }
    
    /// Invoke the closure, with an argument of value, that was passed to the `Lnotice.listen()`
    /// call that returned this LnoticeKey.
    ///
    /// - Parameter value: value to be passed to the original closure
    public func callNow(_ value: T ) {
        receiveValue(value)
    }
    
    public func cancel() {
        cancellable.cancel()
    }
}

///  Lightweight anonymous notification system, implemented via Combine publisher and subscribers.
///  It provides threadsafe many-1 anonymous notification.
///
///  Canonical Use**
///
///  let valueChanged = Lnotice<Float>()
///  let someObject = ...
///  let key1 = valueChanged.listen() { print("New value: \($0)" }
///  let key2 = valueChanged.listen() { someObject.takeValue($0) }
///
///  valueChanged.broadcast(3.14)   // prints  "New value: 3.14" and calls someObject.takeValue(3.14)
///
///  key1.cancel()
///
///  valueChanged.broadcast(1.717)  // only calls someObject.takeValue(1.717)
///
public class Lnotice<T> {
    /// The underlying publisher for this instance.
    public let publisher = PassthroughSubject<T, Never>()

    private var keepAliveObjects = [Any]()
    
    /// Keep data alive.
    ///
    /// - Parameter thing: thing to be kept alive.
    ///
    /// In some cases, an Lnotice object might need to keep other data alive.
    /// Call this function to have the Lnotice hold onto an object.
    ///
    /// It is up to the client to ensure that the held object does not in
    /// turn reference the Lnotice (particularly) via a closure to avoid
    /// reference cycles, as there is no call to remove something from the
    /// list of objects being kept alive.
    ///
    /// This function can be called multiple times.
    public func keepAlive(_ thing: Any) {
        keepAliveObjects.append(thing)
    }

    /// Begin listening to an object.
    ///
    /// When the `broadcast()` function of this instance is invoked, any active closures
    /// are called  with the argument passed to `broadcast().
    ///
    /// The closures are called synchronously from within the `broadcast()` function
    /// unless a specific dispatch queue is specified by dispatchQeueue.
    ///
    /// - returns: A listener key.
    ///
    /// Call the key's `cancel()` method to prevent future calls to the closure.
    /// If the callNow argument is supplied, the passed in closure is immediately invoked
    /// with the callNow arguments (ignoring any value of dispatchQueue).
    @discardableResult
    public func listen(callNow params: T? = nil, dispatchQueue: DispatchQueue? = nil,
                       receiveValue: @escaping ((T ) -> ())) -> LnoticeKey<T> {
        let cancellable: AnyCancellable
        if let dispatchQueue = dispatchQueue {
            cancellable = publisher.receive(on: dispatchQueue).sink { receiveValue($0) }
        }
        else {
            cancellable = publisher.sink { receiveValue($0) }
        }

        let lnoticeKey = LnoticeKey(cancellable: cancellable, receiveValue: receiveValue)
        if let params = params {
            lnoticeKey.callNow(params)
        }
        return lnoticeKey
    }
    
    ///  Broadcast a change to all listeners.
    ///
    ///  All registered callbacks/closures are called synchronously with the value `T `.
    public func broadcast(_ value : T) {
        publisher.send(value)
    }
}

