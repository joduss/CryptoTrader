//
//  CleanPrint.swift
//  Trader2
//
//  Created by Jonathan Duss on 12.01.21.
//

import Foundation

func sourcePrint(_ message: String, _ source: String = #file) {
    print("[\(Date())] [\(source.fileName())] \(message)")
}

func timedPrint(_ message: String) {
    print("[\(Date())] \(message)")
}
