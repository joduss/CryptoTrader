//
//  CleanPrint.swift
//  Trader2
//
//  Created by Jonathan Duss on 12.01.21.
//

import Foundation

/// Prints as if it was a log: [Date] [Class name] Message
func sourcePrint(_ message: String, _ source: String = #file) {
    print("[\(Date())] [\(source.fileName())] \(message)")
}
