//
//  StringExtensions.swift
//  Trader2
//
//  Created by Jonathan Duss on 12.01.21.
//

import Foundation

extension String {
    
    public func fileName() -> String {
        let filepath = self as NSString
        let lastComponent = filepath.lastPathComponent as NSString
        return lastComponent.deletingPathExtension
    }
    
    public func expandedPath() -> String {
        
        if self == "." {
            return FileManager.default.currentDirectoryPath
        }
        
        if self.starts(with: "~") {
            return (self as NSString).abbreviatingWithTildeInPath
        }
        
        if self.starts(with: "/") {
            return self
        }
        
        if self.starts(with: ".") {
            var selfCopy = self
            selfCopy.removeFirst()
            return (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(selfCopy)
        }
        
        return (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(self)
    }
    
}
