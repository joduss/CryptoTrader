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
    
}
