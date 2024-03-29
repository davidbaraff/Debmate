//
//  Reachability.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

#if os(Linux)
import OpenCombineShim
#else
#if !os(watchOS)
import SystemConfiguration
#endif
import Combine
#endif

#if !os(Linux) && !os(watchOS)
fileprivate func callback(reachability :SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
    reachability.reachabilityChanged()
}
#endif

/// A class containing a publisher that monitors changes in network reachability for a particular host.
public class Reachability {
    /// Name of the host being monitored.
    public let hostName: String

    /// A publisher whose current value indicates if the host is reachable or not.
    public let publisher: CurrentValueSubject<Bool, Never>

    /// Same as publisher except it doesn't fire initially.
    public let onChangePublisher: PassthroughSubject<Bool, Never>
    
    /// Current connection status.
    public var connected: Bool {
        publisher.value
    }

    #if !os(Linux) && !os(watchOS)
    let connectionTestPublisher: (() -> AnyPublisher<Bool, Error>)
    var reachabilityRef: SCNetworkReachability!
    var recheckScheduled = false
    let reachabilitySerialQueue = DispatchQueue(label: "com.debmate.reachability")
    #endif

    /// Construct a new instance.
    /// - Parameters:
    ///   - hostName: host to be contacted
    ///   - initialState: if the starting state (before it is actually known) is deemed connected or not
    ///   - connectionTestPublisher: a publisher that yields if the host can be contacted or not
    public init(hostName: String, initialState: Bool, connectionTestPublisher:  @escaping (() -> AnyPublisher<Bool, Error>))  {
        self.hostName = hostName
        #if !os(Linux) && !os(watchOS)
        self.connectionTestPublisher = connectionTestPublisher
        #endif
        self.publisher = CurrentValueSubject(initialState)
        self.onChangePublisher = PassthroughSubject()

        #if !os(Linux) && !os(watchOS)
        guard let rref = SCNetworkReachabilityCreateWithName(nil, hostName) else {
            fatalErrorForCrashReport("Failed to start reachability service for \(hostName)")
        }
        
        reachabilityRef = rref
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) ||
            !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            fatalErrorForCrashReport("Failed to start reachability service")
        }

        reachabilitySerialQueue.async {
            self.reachabilityChanged()
        }

        #endif
    }

    #if !os(Linux) && !os(watchOS)
    deinit {
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    var cancelKey: AnyCancellable?
    
    fileprivate func reachabilityChanged() {
        guard !recheckScheduled else { return }
        
        recheckScheduled = true
        let publisher = self.publisher
        let onChangePublisher = self.onChangePublisher
        
        reachabilitySerialQueue.asyncAfter(deadline: .now() + 2.0) {
            self.recheckScheduled = false

            self.cancelKey = self.connectionTestPublisher().sink(receiveCompletion: { completion in
                let connected: Bool
                switch completion {
                case .finished: connected = true
                case  .failure: connected = false
                }

                if publisher.value != connected {
                    publisher.send(connected)
                    onChangePublisher.send(connected)
                }
            }, receiveValue: { _ in () })
        }
    }
    #endif
}
