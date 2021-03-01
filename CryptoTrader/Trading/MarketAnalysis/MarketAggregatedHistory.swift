import Foundation

final class MarketAggregatedHistory: MarketHistorySlice {
    
    private let intervalToKeep: TimeInterval
    
    private var lastCleanup = 0
    
    private var currentTrade: DatedPrice? = nil
    private var currentTradeAggregationCount = 0.0
    private var aggregationPeriod: TimeInterval
    
    init(intervalToKeep: TimeInterval, aggregationPeriod: TimeInterval = 1) {
        self.intervalToKeep = intervalToKeep
        self.aggregationPeriod = aggregationPeriod
        super.init(prices: ArraySlice<DatedPrice>())
        self.prices.reserveCapacity(1000000)
    }
    
    /// Add a record to the market history.
    func record(_ newTrade: DatedPrice) {
        
        guard let currentTrade = self.currentTrade else {
            self.currentTrade = newTrade
            prices.append(newTrade)
            currentTradeAggregationCount = 1
            return
        }
        
        if newTrade.date - currentTrade.date > aggregationPeriod {
            prices.append(currentTrade)
            self.currentTrade = newTrade
            currentTradeAggregationCount = 1
            
            lastCleanup += 1

            if lastCleanup % 1000 == 0 {
                lastCleanup = 0
                cleanup()
            }
        }
        else {
            let secondAggregatedTrade =
                DatedPrice(
                    price: (currentTrade.price * currentTradeAggregationCount + newTrade.price) / (currentTradeAggregationCount + 1),
                    date: currentTrade.date)
            currentTradeAggregationCount += 1
            self.currentTrade = secondAggregatedTrade
            self.prices.removeLast()
            self.prices.append(secondAggregatedTrade)
        }
    }
    
    /// Remove too old data.
    private func cleanup() {
        for index in 0..<prices.endIndex {
            let price = prices[index]
            
            if (DateFactory.now - price.date > intervalToKeep) {
                continue
            }
            
            if index == 0 { return }
            
            self.prices.removeSubrange(0..<index)            
            return
        }
    }
}
