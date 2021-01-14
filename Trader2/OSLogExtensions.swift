//
//  OSLogExtension.swift
//  Measured Examinator
//
//  Created by Jonathan Duss on 24.11.20.
//

import Foundation
import os

/// Extension to make basic use of OSLog easier.
extension OSLog {
    
//    convenience init(category: String) {
//        self.init(subsystem: Bundle.main.bundleIdentifier!, category: category)
//    }
//
//    convenience init(_ file: String = #file) {
//        let filepath = file as NSString
//        let lastComponent = filepath.lastPathComponent as NSString
//        self.init(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: lastComponent.lastPathComponent)
//    }
//
//    public func debug(_ message: String) {
//        os_log("%@", log: self, type: .debug, message)
//    }
//
//    public func info(message: String) {
//        os_log("%@", log: self, type: .info, message)
//    }
//
//    public func warning(message: String) {
//        os_log("%@", log: self, type: .error, message)
//    }
//
//    public func error(message: String) {
//        os_log("%@", log: self, type: .error, message)
//    }
    
    public static func info(_ message: String, _ file: String = #file) {
        os_log(.info, log: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "no.bundle.id", category: file.fileName()), "%@", message)
    }
    
    public static func debug(_ message: String, _ file: String = #file) {
        os_log(.debug, log: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "no.bundle.id", category: file.fileName()), "%@", message)
    }
}
