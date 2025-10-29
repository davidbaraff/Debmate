//
//  Bool.swift
//  Debmate
//
//  Created by David Baraff on 12/1/24.
//

import Synchronization

public extension Bool {
    var asInt: Int {
        self ? 1 : 0
    }
    
    init(fromInt i: Int) {
        self = i != 0
    }
    
    @available(iOS 18.0, *)
    @available(watchOS 11.0, *)
    class Locked {
        private let mutex: Mutex<Bool>
        
        public init(_ initialValue: Bool) {
            mutex = Mutex(initialValue)
        }
        
        public var value: Bool {
            get { mutex.withLock { $0 } }
            set { mutex.withLock { $0 = newValue } }
        }
    }
}
