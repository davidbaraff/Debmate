//
//  Reachability.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import SystemConfiguration
import Foundation

fileprivate func callback(reachability :SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
    reachability.reachabilityChanged()
}

internal class Reachability {
    static func lnoticeForHost(_ host: String, initialState: Bool, _ connectionTest: @escaping (() -> Bool)) -> Lnotice<Bool> {
        let lnotice = Lnotice<Bool>()
        guard let reachability = Reachability(host, lnotice, initialState, connectionTest) else {
            debugPrint("Failed to create reachability object")
            return lnotice
        }
        
        lnotice.keepAlive(reachability)
        return lnotice
    }
    
    weak var lnotice:Lnotice<Bool>!
    var lastConnectedState: Bool
    let connectionTest: () -> Bool
    var reachabilityRef: SCNetworkReachability!
    let reachabilitySerialQueue = DispatchQueue(label: "com.debmate.reachability")
    var recheckScheduled = false

    init?(_ hostname: String, _ lnotice: Lnotice<Bool>, _ initialState: Bool, _ connectionTest: @escaping (() -> Bool)) {
        self.lnotice = lnotice
        self.connectionTest = connectionTest
        lastConnectedState = initialState
        guard let rref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            return nil
        }
        
        reachabilityRef = rref
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) ||
            !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            debugPrint("Failed to start reachability service")
            return nil
        }
        
        reachabilitySerialQueue.async {
            self.reachabilityChanged()
        }
    }

    deinit {
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    
    fileprivate func reachabilityChanged() {
        guard !recheckScheduled else { return }
        
        recheckScheduled = true
        reachabilitySerialQueue.asyncAfter(deadline: .now() + 2.0) {
            let connected = self.connectionTest()
            if self.lastConnectedState != connected {
                self.lastConnectedState = connected
                DispatchQueue.main.async {
                    self.lnotice.broadcast(connected)
                }
            }
            self.recheckScheduled = false
        }
    }
}
