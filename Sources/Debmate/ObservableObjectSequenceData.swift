//
//  PureModelDataSequenceWatcher.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import DebmateC
import Combine

///
/// Use this class to ensure that any change to the sequence of type T, or one of its elements,
/// is reflected to UserDefaults.
public class ObservableObjectSequenceData<SequenceType : Sequence> where SequenceType.Element : ObservableObject {
    @Published public var value: SequenceType {
        didSet {
            if deferredWriteLevel == 0 /* && value != oldValue*/ {
                print("Writing user defaults: \(value) stored under \(keyName)")
                UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
                recomputeCancelKeys()
            }
        }
    }

    let keyName: String
    var elementCancelKeys = [Cancellable]()
    var refreshHelper: RefreshHelper!
    
    /// Create an ObservableObjectSequenceData<> instance.
    ///
    /// - Parameters:
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    public init(_ keyName: String, defaultValue: SequenceType) {
        self.keyName = keyName
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [keyName : serializableDefaultValue]) }) {
            if (defaultValue as? DiskCachable) == nil {
                fatalErrorForCrashReport("Type \(String(describing: SequenceType.self)) does not conform to DiskCachable")
            }
            else {
                fatalErrorForCrashReport("The encoding of \(String(describing: SequenceType.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
            }
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: keyName) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            value = defaultValue
        }

        refreshHelper = RefreshHelper {  [weak self] in self?.forcedSave() }
        recomputeCancelKeys()
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
        // let oldValue = value
        deferredWriteLevel += 1
        block()
        deferredWriteLevel -= 1

        if /* value != oldValue*/ true {
            print("Deferred writing user defaults: \(value) stored under \(keyName)")
            UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
        }
    }
    
    private func recomputeCancelKeys() {
        for key in elementCancelKeys {
            key.cancel()
        }
        elementCancelKeys = value.map {
            return $0.objectWillChange.sink { _ in
                self.refreshHelper.updateNeeded()
            }
        }
    }
    
    /// Forces the current data to be saved to UserDefaults (even if unchanged).
    public func forcedSave() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: keyName)
    }
}
