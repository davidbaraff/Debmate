//
//  CombineExtensions.swift
//  Debmate
//
//   Copyright © 2021 David Baraff. All rights reserved.
//

import Combine

fileprivate var keepAlives = [Cancellable]()

public extension CurrentValueSubject where Failure == Never  {
    /// Attaches a subscriber with closure-based behavior to a publisher that never fails.
    /// - Parameters:
    ///   - callNow: true to immediately invoke the closure with the current value.
    ///   - receiveValue: The closure to execute on receipt of a value.
    ///
    /// This form of sink does not return a cancellable; instead, the cancellable is
    /// retained internally forever, insuring that the subcription stream is never
    /// torn down.
    func sinkForever(callNow: Bool, receiveValue: @escaping ((Output) -> Void)) {
        if callNow {
            receiveValue(self.value)
        }
        keepAlives.append(self.sink(receiveValue: receiveValue))
    }

    /// Attaches a subscriber with closure-based behavior to a publisher that never fails.
    /// - Parameters:
    ///   - callNow: true to immediately invoke the closure with the current value.
    ///   - receiveValue: The closure to execute on receipt of a value.
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value.
    /// Deallocation of the result will tear down the subscription stream.
    func sink(callNow: Bool, receiveValue: @escaping ((Output) -> Void)) -> AnyCancellable {
        if callNow {
            receiveValue(self.value)
        }
        return sink(receiveValue: receiveValue)
    }
}