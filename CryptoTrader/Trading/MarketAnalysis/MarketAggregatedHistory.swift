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
        super.init(prices: ContiguousArray<DatedPrice>()[0..<0])
        self.prices.reserveCapacity(10000000)
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
            self.prices[self.prices.endIndex - 1] = secondAggregatedTrade
        }
    }
    
    /// Remove too old data.
    public func cleanup() {
        if self.prices.count < 2 { return }
        if self.prices.last!.date - self.prices.first!.date < intervalToKeep { return }
        
        self.prices.withUnsafeBufferPointer({
            unsafePrices in
            
            var idx = 0

            for price in unsafePrices {
                idx += 1
                if (prices.last!.date - price.date > intervalToKeep) {
                    continue
                }
                
                if idx == 0 { return }
                
                self.prices.removeSubrange(0..<idx)
                return
            }
        })
    }
}
