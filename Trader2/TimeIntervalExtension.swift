//
//  TimeIntervalExtension.swift
//  Trader2
//
//  Created by Jonathan Duss on 10.01.21.
//

import Foundation

extension TimeInterval {
    
    static func fromDays(_ days: Double) -> TimeInterval {
        return TimeInterval(days * 24 * 3600)
    }
    
    static func fromHours(_ hours: Double) -> TimeInterval {
        return TimeInterval(hours * 3600)
    }
    
    static func fromMinutes(_ minutes: Double) -> TimeInterval {
        return TimeInterval(minutes * 60)
    }
    
}
