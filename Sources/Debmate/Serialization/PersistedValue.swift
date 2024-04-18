//
//  PersistedValue.swift
//  Debmate
//
//  Copyright © 2024 David Baraff. All rights reserved.
//

#if !os(Linux)

import DebmateC
import SwiftUI
import Foundation

/// An observable value that stores itself persistently in UserDefaults.

private class _PersistedValueWatcher: ObservableObject {
    
}

@available(iOS 17, macOS 17, tvOS 17, *)
@MainActor
@Observable
final public class PersistedValue<T : Equatable> {
    public let key: String
    var refreshHelper: RefreshHelper!

    public var value: T {
        didSet { refreshHelper.updateNeeded() }
    }
    
    public var binding: Binding<T> {
        Binding(get: { self.value },
                set: { self.value = $0 })
    }

    public var projectedValue: PersistedValue {
        get { self }
    }

    private let watcher = _PersistedValueWatcher()
    

    /// Create a PersistedValue instance.
    ///
    /// - Parameters:
    ///   - defaultValue: Initial value for data if not present in UserDefaults
    ///   - key: The key the value will be stored under in UserDefaults for state restoral.
    ///
    public init(_ defaultValue: T, key keyName: String) {
        key = keyName
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

        refreshHelper = RefreshHelper {  [weak self] in
            self?.flush()
            self?.watcher.objectWillChange.send()
        }
    }
    
    /// Execute work whever the value changes, using objectWillChange semantics.
    public func watchForever(onChange work: @escaping (() -> Void)) {
        watcher.objectWillChange.sinkForever(receiveValue: work)
    }
    
    /// Write value to UserDefaults immediately.
    private func flush() {
        UserDefaults.standard.set(encodeAsCachableAny(value), forKey: key)
    }
}


#endif

