//
//  DateExtensions.swift
//  Trader2
//
//  Created by Jonathan Duss on 10.01.21.
//

import Foundation


extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
    
    static func Now() -> Date {
        return CurrentDate.instance.date
    }

}

class CurrentDate {
    
    static let instance: CurrentDate = CurrentDate()
    
    private init() {}
    
    var date: Date = Date()
}
