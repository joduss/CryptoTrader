//
//  MarketAnalyzer.swift
//  Trader2
//
//  Created by Jonathan Duss on 10.01.21.
//

import Foundation

final class MarketHistory: MarketHistorySlice {
    
    private let intervalToKeep: TimeInterval
    private var lastCleanup = 0
    
    
    init(intervalToKeep: TimeInterval) {
        self.intervalToKeep = intervalToKeep
        super.init(prices: ArraySlice<DatedPrice>())
        self.prices.reserveCapacity(10000)
    }
    
    /// Add a record to the market history.
    func record(_ trade: DatedPrice) {
        prices.append(trade)
        
        lastCleanup += 1
        
        if lastCleanup % 500 == 0 {
            lastCleanup = 0
            cleanup()
        }
    }
    
    /// Remove too old data.
    private func cleanup() {
        for index in 0..<prices.endIndex {
            let price = prices[index]
            
            if (DateFactory.now - price.date > TimeInterval.fromHours(1.01)) {
                continue
            }
            
            if index == 0 { return }
            
            self.prices.removeSubrange(0..<index)
            return
        }
    }
}
