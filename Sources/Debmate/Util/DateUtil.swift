//
//  DateUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

import Foundation

extension Util {
    /// Returns date in a readable form.
    ///
    /// - Parameter date: the date
    /// - Parameter omitTime: if true, the time in the data is omitted
    /// - Returns: textual description
    static public func textualDate(_ date: Date, omitTime: Bool = false) -> String {
        let calendar = NSCalendar.current
        let now = Date()
        
        // Replace the hour (time) of both dates with 00:00
        let cNow = calendar.startOfDay(for: now)
        let cThen = calendar.startOfDay(for: date)
        
        let component = calendar.dateComponents([.day], from: cThen, to: cNow)
        let daysBetween = component.day ?? 100
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        if daysBetween > 3 {
            let year = calendar.component(.year, from: date)
            return "\(month)/\(day)/\(year)"
        }
        else {
            let hour = calendar.component(.hour, from: date)
            let minute = String(format: "%02d", calendar.component(.minute, from: date))
            let hhour = (hour % 12) == 0 ? 12 : (hour % 12)
            let timeStr = omitTime ? "" : "\(hhour):\(minute)\(hour > 11 ? "PM" : "AM")"

            if daysBetween <= 1 {
                let day = (daysBetween == 0) ? "Today" : "Yesterday"
                return "\(day) \(timeStr)"
            }
            else {
                let weekday = calendar.component(.weekday, from: date)
                let dayStr = calendar.shortStandaloneWeekdaySymbols[weekday-1]
                let monthStr = calendar.shortMonthSymbols[month-1]
                let dayNo = String(format: "%02d", day)
                return "\(dayStr), \(monthStr) \(dayNo) \(timeStr)"
            }
        }
    }

    /// Returns the time of a date in readable form.
    /// - Parameter date: the date
    /// - Returns: textual description
    static public func textualTime(_ date: Date) -> String {
        let calendar = NSCalendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = String(format: "%02d", calendar.component(.minute, from: date))
        let hhour = (hour % 12) == 0 ? 12 : (hour % 12)
        return "\(hhour):\(minute)\(hour > 11 ? "PM" : "AM")"
    }

    /// Returns a string of the form <month>-<day> where <month> is a string and <day> is a number
    /// - Parameter date: date
    /// - Returns: date without slashes.
    static public func stringMonthAndDay(_ date: Date) -> String {
        let calendar = NSCalendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let monthStr = calendar.shortMonthSymbols[month-1]
        return "\(monthStr)-\(day)"
    }
    
    /// Returns a string of the form <month>-<date>-<year>
    /// - Parameter date: date
    /// - Returns: date without slashes.
    static public func timelessDateForFilename(_ date: Date) -> String {
        let calendar = NSCalendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return String(format: "%.02d-%.02d-%d", month, day, year)
    }
}
