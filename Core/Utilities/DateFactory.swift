//
//  DateFactory.swift
//  Trader2
//
//  Created by Jonathan Duss on 19.01.21.
//

import Foundation

/// A special date which can be changed.
/// To avoid error, only this class should be used or only Date.
/// A mix of both would have inconsistency!
/// The mutable date returned by 'now' is to be set anywhere and does not change automatically.
class DateFactory {
    
    private var nowDate: Date?
    
    var simulated = false
    
    var now: Date {
        get {
            return simulated ? (nowDate ?? Date()) : Date()
        }
        set {
            simulated = true
            nowDate = newValue
        }
    } 
}
