//
//  MarketAnalyzer.swift
//  Trader2
//
//  Created by Jonathan Duss on 10.01.21.
//

import Foundation

class MarketHistory {
    
    private let intervalToKeep: TimeInterval
    
    private var tickers: ContiguousArray<MarketAggregatedTrade> = ContiguousArray<MarketAggregatedTrade>()
    private var lastCleanup = 0
    
    
    init(intervalToKeep: TimeInterval) {
        tickers.reserveCapacity(100000)
        self.intervalToKeep = intervalToKeep
    }
    
    /// Add a record to the market history.
    func record(_ trade: MarketAggregatedTrade) {
        tickers.append(trade)
        
        lastCleanup += 1
        
        if lastCleanup % 500 == 0 {
            lastCleanup = 0
            cleanup()
        }
    }
    
    /// Returns true if there is history in the past in a time interval from now.
    func hasRecordFromAtLeastPastInterval(_ interval: TimeInterval) -> Bool {
        guard let firstRecord = tickers.first else { return false }
        
        return firstRecord.date <= DateFactory.now.advanced(by: -interval )
    }
    
    /// Remove too old data.
    private func cleanup() {
        for index in 0..<tickers.endIndex {
            let price = tickers[index]
            
            if (DateFactory.now - price.date > TimeInterval.fromHours(1.01)) {
                continue
            }
            
            if index == 0 { return }
            
            self.tickers = ContiguousArray(self.tickers[index..<self.tickers.endIndex])
            return
        }
    }
    
    /// Returns a market history up to a given point back in the past.
    func prices(last interval: TimeInterval) -> MarketHistorySlice {
        return pricesInInterval(beginDate: DateFactory.now.advanced(by: -interval))
    }
    
    /// Returns a market history from a given date to the end or to a specific date.
    func pricesInInterval(beginDate: Date, endDate: Date? = nil) -> MarketHistorySlice {
        
        guard self.tickers.count > 0 else { return MarketHistorySlice(prices: ArraySlice()) }
        let startIdx = findSortedIdx(dateAtLeast: beginDate)!

        if let endDate = endDate {
            let endIdx = findSortedIdx(dateAtMax: endDate)!
            return MarketHistorySlice(prices: self.tickers[startIdx..<endIdx])
        }
        else {
            return MarketHistorySlice(prices: self.tickers[startIdx..<self.tickers.endIndex])
        }
    }
    
    /// Find the index of the largest date smaller or equal than a given date in a sorted array.
    /// Uses the binary search algorithm.
    func findSortedIdx(dateAtMax date: Date) -> Int? {
        guard tickers.count > 0 else { return nil }
        
        if tickers.first!.date > date {
            return nil
        }
        
        if tickers.last!.date <= date {
            return tickers.endIndex-1
        }
        
        var rangeToSearch = 0...(tickers.count-1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range.
            // If the larger element is too large, the smaller might be ok. It still might be larger, so we need to take the one below.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if tickers[rangeToSearch.upperBound].date > date {
                    return tickers[rangeToSearch.lowerBound].date > date ? rangeToSearch.lowerBound - 1 : rangeToSearch.lowerBound
                }
                return rangeToSearch.upperBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if tickers[centerRange].date > date {
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

    /// Find the index of the largest date smaller or equal than a given date in a sorted array.
    /// Uses the binary search algorithm.
    func findSortedIdx(dateAtLeast date: Date) -> Int? {
        guard tickers.count > 0 else { return nil }
        
        if tickers.first!.date >= date {
            return 0
        }
        
        if tickers.last!.date < date {
            return nil
        }
        
        var rangeToSearch = 0...(tickers.count-1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range
            // If the smaller element is too small, we take the larger. It might still be too small. In such case,
            // we take the one above.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if tickers[rangeToSearch.lowerBound].date < date {
                    return tickers[rangeToSearch.upperBound].date >= date ? rangeToSearch.upperBound : rangeToSearch.upperBound + 1
                }
                return rangeToSearch.lowerBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if tickers[centerRange].date >= date {
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
