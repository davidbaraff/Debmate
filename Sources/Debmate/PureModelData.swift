//
//  PureModelData.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation
import DebmateC

/// Class for representing model data tied to state saving.
///
/// The PureModelData class is used to tie a value with
/// notification, and state saving, but without a GUI presence
/// (unlike ModelData).
///
/// For example,
/// ````
///    let modelData = PureModelData("lastIntensityValue", 0.5)
///    modelData.listen {
///       newValue in
///       print("Changed to ", newValue)
///
///       // Note: using modelData here creates a retain cycle
///       print("Note: this should match", modelData.value)
///    }
/// ````
/// Note that if the type of the value is not serializable to UserDefaults,
/// a fatal runtime error will occur when the instance is created.
public class PureModelData<T : Equatable> {
    var curValue: T
    let keyName: String
    
    /// Clients are free to listen directly to this object, but for convenience,
    /// can also call `listen()` directly on the PureModelData instance.
    public let noticeObject = Lnotice<T>()
    
    /// Specify a closure to be run when the value of the control changes.
    @discardableResult
    public func listen(receiveValue: @escaping (T) -> ()) -> LnoticeKey<T> {
        return noticeObject.listen(receiveValue: receiveValue)
    }
    
    /// Specify a closure to be run when the value of the control changes.
    /// Note: this form immediately invokes the closure if callNow is true.
    public func listen(callNow: Bool, receiveValue: @escaping (T) -> ()) -> LnoticeKey<T> {
        let result = noticeObject.listen(receiveValue: receiveValue)
        if callNow {
            result.callNow(curValue)
        }
        return result
    }
    
    /// Create a PureModelData instance.
    ///
    /// - Parameters:
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    public init(_ keyName: String, defaultValue: T) {
        self.keyName = keyName
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [keyName : serializableDefaultValue]) }) {
            if (defaultValue as? DiskCachable) == nil {
                fatalErrorForCrashReport("Type \(String(describing: T.self)) does not conform to DiskCachable")
            }
            else {
                fatalErrorForCrashReport("The encoding of \(String(describing: T.self)) from DiskCachable yields non-property list type \(type(of: serializableDefaultValue))")
            }
        }
        
        if let storedValue = UserDefaults.standard.object(forKey: keyName) {
            curValue = decodeFromCachableAny(storedValue) ?? defaultValue
        }
        else {
            curValue = defaultValue
        }
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
        let oldValue = curValue
        deferredWriteLevel += 1
        block()
        deferredWriteLevel -= 1
        if curValue != oldValue {
            noticeObject.broadcast(curValue)
            UserDefaults.standard.set(encodeAsCachableAny(curValue), forKey: keyName)
        }
    }
    
    /// Get/set the value of the control.
    public var value: T {
        get {
            return curValue
        }
        set(newValue) {
            guard deferredWriteLevel == 0 else {
                curValue = newValue
                return
            }

            if curValue != newValue {
                curValue = newValue
                noticeObject.broadcast(curValue)
                UserDefaults.standard.set(encodeAsCachableAny(curValue), forKey: keyName)
            }
        }
    }
}
