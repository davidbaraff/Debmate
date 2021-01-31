//
//  ClassIdentityBase.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

/// A base class that implements the Hashable procotol.
///
/// A class derived from `ClassIdentityBase` can be placed
/// in containers such as `Set<>` or `Dictionary<>`.  The equality
/// operator is the same as as the `===` operator.
open class ClassIdentityBase : Hashable {
    public init() {
    }
    
    public func hash(into hasher: inout Hasher) {
       hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    /// The raw memory location of this object.
    public var id: UInt {
        return UInt(bitPattern: ObjectIdentifier(self))
    }
}

/// -returns: True iff `lhs` and `rhs` are the same instances.
public func ==(lhs: ClassIdentityBase, rhs:ClassIdentityBase) -> Bool {
    return lhs === rhs
}
