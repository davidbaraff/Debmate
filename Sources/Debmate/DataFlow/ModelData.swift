//
//  ModelData.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

#if !os(Linux) && !os(watchOS)

import Foundation
import DebmateC

#if os(iOS) || os(tvOS)
import UIKit
public protocol ModelDataValuedControl: UIControl {
    var controlValue : Any { get set }
}

#if os(iOS)
extension UISwitch : ModelDataValuedControl {
    public var controlValue: Any {
        get {
            return self.isOn
        }
        
        set(newValue) {
            self.isOn = newValue as! Bool
        }
    }
}
#endif

#else
import Cocoa
public protocol ModelDataValuedControl: NSControl {
    var controlValue : Any { get set }
}
#endif

/// Class for representing model data tied to state saving.
///
/// The ModelData class is used to tie simple GUI elements with a value,
/// notification, and state saving.
///
/// For example,
/// ````
///    let modelData = ModelData(someSlider, "curIntensitySlider", 0.5)
///    modelData.listen {
///       newValue in
///       print("Slider changed to ", newValue)
///
///       // Note: using modelData here creates a retain cycle
///       print("Note: this should match", modelData.value)
///    }
/// ````
/// Additionally, the UISlider element will be reset to its last value by
/// the call to create modelData.  Changes to the slider run the specified
/// closure passed to `listen()`, while the program can directly change the
/// slider itself by
/// ````
///     modelData.value = 0.78
/// ````
/// Any type of control can participate by implementing the ModelDataValuedUIControl.
/// Note that if the type of the value returned by the protocol for a control does not
/// match the type specified for defaultValue in the constructor, a fatal runtime
/// error will occur.

@MainActor
public class ModelData<T : Equatable> {
    weak var control: ModelDataValuedControl?
    var curValue: T
    let keyName: String
    
    /// Clients are free to listen directly to this object, but for convenience,
    /// can call `listen()` on the ModelData instance.
    public let noticeObject = Lnotice<T>()
    
    /// Specify a closure to be run when the value of the control changes;
    /// if callNow is true, the callback is immediately run with the current value
    /// of the control.
    public func listen(callNow: Bool = false, receiveValue: @escaping (T) -> ()) -> LnoticeKey<T> {
        let key = noticeObject.listen(receiveValue: receiveValue)
        if callNow {
            key.callNow(curValue)
        }
        return key
    }
    
    @objc func valueDidChange() {
        guard let control = control else {
            return
        }
        curValue = control.controlValue as! T
        noticeObject.broadcast(curValue)
        UserDefaults.standard.set(curValue, forKey: keyName)
    }

    /// Create a new ModelData instance.
    ///
    /// - Parameters:
    ///   - control: Any kind of GUI control conforming to ModelDataValuedControl.
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for control if not present in UserDefaults
    ///
    /// If the type of defaultValue does not match the actual type returned by the ModelDataValuedUIProtocol
    /// protocol, a fatal error will occur.
    public init(_ control: ModelDataValuedControl, _ keyName: String, defaultValue: T) {
        self.keyName = keyName
        self.control = nil
        curValue = defaultValue
        initializeValue(defaultValue)
        control.controlValue = curValue
        setControl(control)
    }

    /// Create a new ModelData instance.
    ///
    /// - Parameters:
    ///   - keyName: The key the value will be stored under in UserDefaults for state restoral.
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///
    /// This initializer leaves the GUI control set to nil.
    public init(_ keyName: String, defaultValue: T) {
        self.keyName = keyName
        self.control = nil
        curValue = defaultValue
        initializeValue(defaultValue)
    }

    private func initializeValue(_ defaultValue: T) {
        let serializableDefaultValue = encodeAsCachableAny(defaultValue)
        if !Debmate_CatchException({ UserDefaults.standard.register(defaults: [self.keyName : serializableDefaultValue]) }) {
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
    
    /// Update the GUI control attached to this item.
    ///
    /// - Parameters:
    ///   - control: Any kind of UIControl which implements the ModelDataValuedUIControl protocol.
    ///
    /// If the type of defaultValue (passed in the constructor) does not match the actual
    /// type returned by the ModelDataValuedControl protocol for control, a fatal error will occur.
    public func setControl(_ control: ModelDataValuedControl?) {
        if self.control === control {
            return
        }
        
        #if os(iOS) || os(tvOS)
        self.control?.removeTarget(self, action: #selector(valueDidChange), for: [.valueChanged])
        //#else
        //fatalErrorForCrashReport("unimplemented for macOS")
        #endif
        
        guard let control = control else {
            return
        }
        
        let testValue = control.controlValue
        guard ((testValue as? T) != nil) else {
            let controlType = String(describing: type(of: control))
            let tStr = String(describing: T.self)
            let vStr = String(describing: type(of: testValue))
            fatalError("ModelData<\(tStr)> is incompataible with GUI control type \(controlType) (data type: \(vStr)")
        }
        
        self.control = control
        control.controlValue = curValue
        
        #if os(iOS) || os(tvOS)
        control.addTarget(self, action: #selector(valueDidChange), for: [.valueChanged])
        #else
        fatalErrorForCrashReport("unimplemented for macOS")
        #endif
    }
    
    /// Get/set the value of the control.
    public var value: T {
        get {
            return curValue
        }
        set(newValue) {
            if curValue != newValue {
                curValue = newValue
                control?.controlValue = newValue
                noticeObject.broadcast(curValue)
                UserDefaults.standard.set(encodeAsCachableAny(curValue), forKey: keyName)
            }
        }
    }
}
#endif

