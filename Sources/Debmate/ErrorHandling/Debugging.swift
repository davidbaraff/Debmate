//
//  Debugging.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

public var logOnCrash: ((String) -> ())?

private func fileForFatalErrorCrashReport() -> URL {
    return Util.cachesDirectory.appendingPathComponent("debmate-crashreport-msg")
}

///  Issue a fatal error.
///
///  Unlike the built-in fatalError() routine, this version makes the diagnostics
///  information available to a crash reporter at the next system startup, via
///  `fatalErrorForCrashReportMessage()`.
///
///  - parameter msg: failure message
///  - parameter file:    file the fatal error was issued from
///  - parameter line:    line number the fatal error was issued from
public func fatalErrorForCrashReport(_ msg: String, file: StaticString = #file,  line: UInt = #line, function: StaticString = #function) -> Never  {
    let fullMsg = "Fatal error: \(msg) [\(function), \(file):\(line)]"
    
    if let logOnCrash = logOnCrash {
        logOnCrash(fullMsg)
    }
    
    do {
        try fullMsg.write(to: fileForFatalErrorCrashReport(), atomically: true, encoding: .utf8)
    }
    catch {
        debugPrint("Failed to write fatal error crash report: \(error)")
    }
    
    fatalError(msg, file: file, line: line)
}

/// Return the message last written by a call to fatalErrorForCrashReport().
/// - parameter deleteOnRead: if true, deletes the backing file storing the message
///   after the message is read
/// - Returns: last message sent by fatalErrorForCrashReport
public func fatalErrorForCrashReportMessage(deleteOnRead: Bool = true) -> String? {
    if let msg = try? String(contentsOf: fileForFatalErrorCrashReport()) {
        if deleteOnRead {
            try? FileManager.default.removeItem(at: fileForFatalErrorCrashReport())
        }
        return msg
    }
    return nil
}

/// Return the address of an object as a hex string.
///
/// - Parameter obj: object being debugged
/// - Returns: address as a hex string
public func addressInHex<T : AnyObject>(_ obj: T) -> String {
    let addr = UInt(bitPattern: ObjectIdentifier(obj))
    return String(format: "0x%x", addr)
}

/// Return true if an application appears to be in "sandbox" mode.
///
/// An application is if sandbox mode if it was installed via the app store or
/// some mobile enterprise facility.
public func apnsSandboxMode() -> Bool {
    guard let fileName = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
        return false
    }
    
    let fileURL = URL(fileURLWithPath: fileName)
    // the documentation says this file is in UTF-8, but that failed
    // on my machine. ASCII encoding worked ¯\_(ツ)_/¯
    guard let data = try? String(contentsOf: fileURL, encoding: .ascii) else {
        return false
    }
    
    let cleared: String = data.components(separatedBy: .whitespacesAndNewlines).joined()
    return cleared.contains("<key>get-task-allow</key><true/>")
}

