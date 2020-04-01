//
//  ObservableObjectData.swift
//  Debmate
//
//  Copyright © 2020 David Baraff. All rights reserved.
//

import Foundation
import DebmateC
import Combine

/// Class for representing model data tied to state saving.
///
/// The ObservableObjectData class is used to automatically save observable
/// objects to UserDefaults, while also allowing for anonymous notification when any
/// (published) )member of the observable object changes.
///
public class ObservableObjectData<T : ObservableObject & CodableDiskCachable> {
    typealias Element = T
    public var value: T {
        didSet {
            forcedSave()
            watchValue()
        }
    }

    let keyName: String
    var primaryCancellable: Cancellable?
    var refreshHelper: RefreshHelper!
    
/*
    /// Specify a closure to be run when the value of the control changes.
    ///
    /// The returned Cancelable must be retained for the closure to be called when the value changes.
    public func listen(receiveValue: @escaping (T) -> ()) -> Cancellable {
        return value.objectWillChange.sink { _ in DispatchQueue.main.async { receiveValue(self.value) } }
    }
    
    /// Specify a closure to be run when the value of the control changes.
    ///
    /// Tthis form immediately invokes the closure if callNow is true.
    ///
    /// The returned Cancelable must be retained for the closure to be called when the value changes.
    public func listen(callNow: Bool, receiveValue: @escaping (T) -> ()) -> Cancellable {
        let result = listen(receiveValue: receiveValue)
        if callNow {
            receiveValue(value)
        }
        return result
    }
*/
    
    /// Create an ObservableObjectData instance.
    ///
    /// - Parameters:
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    public init(_ keyName: String, defaultValue: T) {
        self.keyName = keyName
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [keyName : serializableDefaultValue]) }) {
            fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: keyName) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            value = defaultValue
        }

        watchValue()
        refreshHelper = RefreshHelper {  [weak self] in self?.forcedSave() }
    }
    
    private var deferredWriteLevel = 0
    
    /// Group updates into one.
    /// - Parameter block: update code
    ///
    /// Upon completion of block(), a notice is emitted and data is synchronized to UserDefaults
    /// if value has been changed.
    ///
    /// This function should only be called on the main dispatch queue.
    public func batchUpdate(block: () -> ()) {
        deferredWriteLevel += 1
        block()
        deferredWriteLevel -= 1

        if /*value != oldValue*/ true {
            print("Deferred writing user defaults: \(value) stored under \(keyName)")
            UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
        }
    }
    
    private func forcedSave() {
        print("Regular update saving \(self)")
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
    }
    
    private func watchValue() {
        primaryCancellable?.cancel()
        primaryCancellable = value.objectWillChange.sink { [weak self] _ in self?.refreshHelper.updateNeeded() }
    }
}
