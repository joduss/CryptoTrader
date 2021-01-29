import Foundation

class MarketPerSecondHistory {
    
    private let intervalToKeep: TimeInterval
    
    private var trades: ContiguousArray<MarketAggregatedTrade> = ContiguousArray<MarketAggregatedTrade>()
    private var lastCleanup = 0
    
    private var currentTrade: MarketAggregatedTrade?
    private var currentTradeAggregationCount = 0.0
    
    init(intervalToKeep: TimeInterval) {
        trades.reserveCapacity(100000)
        self.intervalToKeep = intervalToKeep
    }
    
    /// Add a record to the market history.
    func record(_ newTrade: MarketAggregatedTrade) {
        
        guard let currentTrade = self.currentTrade else {
            self.currentTrade = newTrade
            currentTradeAggregationCount = 1
            return
        }
        
        if newTrade.date - currentTrade.date > 1 {
            trades.append(currentTrade)
            self.currentTrade = newTrade
            currentTradeAggregationCount = 1
            
            lastCleanup += 1

            if lastCleanup % 500 == 0 {
                lastCleanup = 0
                cleanup()
            }
        }
        else {
            let secondAggregatedTrade =
                MarketAggregatedTrade(
                    id: 0,
                    date: currentTrade.date,
                    symbol: currentTrade.symbol,
                    price: (currentTrade.price * currentTradeAggregationCount + newTrade.price) / (currentTradeAggregationCount + 1),
                    quantity: currentTrade.quantity + newTrade.quantity,
                    buyerIsMaker: true)
            currentTradeAggregationCount += 1
            self.currentTrade = secondAggregatedTrade
        }
    }
    
    /// Returns true if there is history in the past in a time interval from now.
    func hasRecordFromAtLeastPastInterval(_ interval: TimeInterval) -> Bool {
        guard let firstRecord = trades.first else { return false }
        
        return firstRecord.date <= DateFactory.now.advanced(by: -interval )
    }
    
    /// Remove too old data.
    private func cleanup() {
        for index in 0..<trades.endIndex {
            let price = trades[index]
            
            if (DateFactory.now - price.date > intervalToKeep) {
                continue
            }
            
            if index == 0 { return }
            
            self.trades = ContiguousArray(self.trades[index..<self.trades.endIndex])
            return
        }
    }
    
    /// Returns a market history up to a given point back in the past.
    func prices(last interval: TimeInterval) -> MarketHistorySlice? {
        return pricesInInterval(beginDate: DateFactory.now.advanced(by: -interval))
    }
    
    /// Returns a market history from a given date to the end or to a specific date.
    func pricesInInterval(beginDate: Date, endDate: Date? = nil) -> MarketHistorySlice? {
        
        guard self.trades.count > 0 else { return MarketHistorySlice(prices: ArraySlice()) }
        guard let startIdx = findSortedIdx(dateAtLeast: beginDate) else {
            return nil
        }

        if let endDate = endDate {
            let endIdx = findSortedIdx(dateAtMax: endDate)!
            return MarketHistorySlice(prices: self.trades[startIdx..<endIdx])
        }
        else {
            return MarketHistorySlice(prices: self.trades[startIdx..<self.trades.endIndex])
        }
    }
    
    /// Find the index of the largest date smaller or equal than a given date in a sorted array.
    /// Uses the binary search algorithm.
    func findSortedIdx(dateAtMax date: Date) -> Int? {
        guard trades.count > 0 else { return nil }
        
        if trades.first!.date > date {
            return nil
        }
        
        if trades.last!.date <= date {
            return trades.endIndex-1
        }
        
        var rangeToSearch = 0...(trades.count-1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range.
            // If the larger element is too large, the smaller might be ok. It still might be larger, so we need to take the one below.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if trades[rangeToSearch.upperBound].date > date {
                    return trades[rangeToSearch.lowerBound].date > date ? rangeToSearch.lowerBound - 1 : rangeToSearch.lowerBound
                }
                return rangeToSearch.upperBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if trades[centerRange].date > date {
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
        guard trades.count > 0 else { return nil }
        
        if trades.first!.date >= date {
            return 0
        }
        
        if trades.last!.date < date {
            return nil
        }
        
        var rangeToSearch = 0...(trades.count-1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range
            // If the smaller element is too small, we take the larger. It might still be too small. In such case,
            // we take the one above.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if trades[rangeToSearch.lowerBound].date < date {
                    return trades[rangeToSearch.upperBound].date >= date ? rangeToSearch.upperBound : rangeToSearch.upperBound + 1
                }
                return rangeToSearch.lowerBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if trades[centerRange].date >= date {
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
