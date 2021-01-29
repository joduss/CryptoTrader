//
//  CleanPrint.swift
//  Trader2
//
//  Created by Jonathan Duss on 12.01.21.
//

import Foundation

/// Prints as if it was a log: [Date] [Class name] Message
func sourcePrint(_ message: String, _ source: String = #file) {
    print("[\(DateFactory.now)] [\(source.fileName())] \(message)")
}

func sourceReplacablePrint(_ message: String, _ source: String = #file) {
    print("\u{1B}[2K\u{1B}7[\(DateFactory.now)] [\(source.fileName())] \(message) \u{1B}8", terminator: "")
    fflush(stdout)
}
