//
//  MarketAnalyzer.swift
//  Trader2
//
//  Created by Jonathan Duss on 10.01.21.
//

import Foundation
import JoLibrary

class MarketHistory {
    
    private let intervalToKeep: TimeInterval
    
    private var prices: ContiguousArray<PriceRecord> = ContiguousArray<PriceRecord>()
    
    private var lastCleanup = 0
    
    init(intervalToKeep: TimeInterval) {
        prices.reserveCapacity(100000)
        self.intervalToKeep = intervalToKeep
    }
    
    func record(_ price: Double) {
        prices.append(PriceRecord(time: Date.Now(), price: price))
        
        lastCleanup += 1
        
        if lastCleanup % 500 == 0 {
            lastCleanup = 0
            cleanup()
        }
    }
    
    func hasRecordFromAtLeastPastInterval(_ interval: TimeInterval) -> Bool {
        guard let firstRecord = prices.first else { return false }
        
        return firstRecord.time <= Date.Now().advanced(by: -interval )
    }
    
    private func cleanup() {
        for index in 0..<prices.endIndex {
            let price = prices[index]
            
            if (Date.Now() - price.time > TimeInterval.fromHours(1.01)) {
                continue
            }
            
            if index == 0 { return }
            
            self.prices = ContiguousArray(self.prices[index..<self.prices.endIndex])
            return
        }
    }
    
    func prices(last interval: TimeInterval) -> MarketHistorySlice {
        return pricesInInterval(beginDate: Date.Now().advanced(by: -interval))
    }
    
    func pricesInInterval(beginDate: Date, endDate: Date? = nil) -> MarketHistorySlice {
        
        guard self.prices.count > 0 else { return MarketHistorySlice(prices: ArraySlice()) }
        let startIdx = findSortedIdx(dateAtLeast: beginDate)!

        if let endDate = endDate {
            exit(1)
            return MarketHistorySlice(prices: ArraySlice())
//            let startIdx = findSortedIdx(dateAtMax: beginDate)!
//            return MarketHistorySlice(values: self.prices[startIdx..<self.prices.endIndex])
        }
        else {
            return MarketHistorySlice(prices: self.prices[startIdx..<self.prices.endIndex])
        }
    }
    
    func findSortedIdx(dateAtMax date: Date) -> Int? {
        guard prices.count > 0 else { return nil }
        
        if prices.first!.time > date {
            return nil
        }
        
        if prices.last!.time <= date {
            return prices.endIndex-1
        }
        
        var rangeToSearch = 0...(prices.count-1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range.
            // If the larger element is too large, the smaller might be ok. It still might be larger, so we need to take the one below.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if prices[rangeToSearch.upperBound].time > date {
                    return prices[rangeToSearch.lowerBound].time > date ? rangeToSearch.lowerBound - 1 : rangeToSearch.lowerBound
                }
                return rangeToSearch.upperBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if prices[centerRange].time > date {
                // If the value is larger or equal, we should search smaller values.
                rangeToSearch =  (rangeToSearch.lowerBound)...(centerRange-1)
            }
            else {
                // if the value is smaller, Then we need to search on the right, where larger values are to find the largest value
                // not too big.
                rangeToSearch = (centerRange)...rangeToSearch.upperBound

            }
        }
        
        return rangeToSearch.lowerBound
    }

    func findSortedIdx(dateAtLeast date: Date) -> Int? {
        guard prices.count > 0 else { return nil }
        
        if prices.first!.time >= date {
            return 0
        }
        
        if prices.last!.time < date {
            return nil
        }
        
        var rangeToSearch = 0...(prices.count-1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range
            // If the smaller element is too small, we take the larger. It might still be too small. In such case,
            // we take the one above.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if prices[rangeToSearch.lowerBound].time < date {
                    return prices[rangeToSearch.upperBound].time >= date ? rangeToSearch.upperBound : rangeToSearch.upperBound + 1
                }
                return rangeToSearch.lowerBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if prices[centerRange].time >= date {
                // If the value is larger or equal, we should search smaller values right large enough on the left.
                rangeToSearch =  (rangeToSearch.lowerBound)...centerRange
            }
            else {

                // if the value is smaller, Then we need to search on the right, where larger values are.
                rangeToSearch = (centerRange + 1)...rangeToSearch.upperBound

            }
        }
        
        return rangeToSearch.lowerBound
    }
}
