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
@propertyWrapper
public class ModelObjects<SequenceType : Sequence> : ObservableObject where SequenceType.Element : ObservableObject {
    @Published public var value: SequenceType  

    public var wrappedValue: SequenceType {
        get { value }
        set {
            value = newValue
            if deferredWriteLevel == 0 {
                flush()
            }
            recomputeCancelKeys()
        }
    }

    public var projectedValue: ModelObjects {
        get { self }
    }

    let key: String
    var elementCancelKeys = [Cancellable]()
    var refreshHelper: RefreshHelper!
    
    /// Create an ObservableObjectSequenceData<> instance.
    ///
    /// - Parameters:
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    public init(wrappedValue defaultValue: SequenceType, key keyName: String) {
        key = keyName
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: ["keyName" : serializableDefaultValue]) }) {
            if (defaultValue as? DiskCachable) == nil {
                fatalErrorForCrashReport("Type \(String(describing: SequenceType.self)) does not conform to DiskCachable")
            }
            else {
                fatalErrorForCrashReport("The encoding of \(String(describing: SequenceType.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
            }
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: key) {
            value = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            value = defaultValue
        }

        refreshHelper = RefreshHelper {  [weak self] in self?.flush() }
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

        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
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
    public func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
}
