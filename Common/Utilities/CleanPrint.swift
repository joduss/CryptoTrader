//
//  CleanPrint.swift
//  Trader2
//
//  Created by Jonathan Duss on 12.01.21.
//

import Foundation

class OutputDateFormatter {
    fileprivate var dateFormatter = DateFormatter()
    
    static var instance = OutputDateFormatter()
    
    fileprivate init() {
        dateFormatter.dateFormat = "dd.MM.YY HH:mm:ss"
    }

    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}


/// Prints as if it was a log: [Date] [Class name] Message
func sourcePrint(_ message: String, _ source: String = #file) {
    let prefix = "[\(OutputDateFormatter.instance.format(date: DateFactory.now))] [\(source.fileName())] "
    print("\(prefix)\(formatMessage(message, prefix: prefix))")
}

func sourceReplacablePrint(_ message: String, _ source: String = #file) {
    print("\u{1B}[2K\u{1B}7[\(OutputDateFormatter.instance.format(date: DateFactory.now))] [\(source.fileName())] \(message) \u{1B}8", terminator: "")
    fflush(stdout)
}

fileprivate func formatMessage(_ message: String, prefix: String) -> String {
    guard message.contains("\n") else {
        return message
    }
    
    let alignmentSpace = String(repeating: " ", count: prefix.count)

    var lines = message.split(separator: "\n")
    var formattedMessage = String(lines.removeFirst())
    
    for line in lines {
        formattedMessage += "\n\(alignmentSpace)\(line)"
    }
    
    
    
    return formattedMessage
}
