import Foundation

final class MarketPerSecondHistory: MarketHistorySlice {
    
    private let intervalToKeep: TimeInterval
    
    private var lastCleanup = 0
    
    private var currentTrade: MarketAggregatedTrade? = nil
    private var currentTradeAggregationCount = 0.0
    
    init(intervalToKeep: TimeInterval) {
        self.intervalToKeep = intervalToKeep
        super.init(prices: ArraySlice<MarketAggregatedTrade>())
        self.prices.reserveCapacity(100000)
    }
    
    /// Add a record to the market history.
    func record(_ newTrade: MarketAggregatedTrade) {
        
        guard let currentTrade = self.currentTrade else {
            self.currentTrade = newTrade
            prices.append(newTrade)
            currentTradeAggregationCount = 1
            return
        }
        
        if newTrade.date - currentTrade.date > 1 {
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
                MarketAggregatedTrade(
                    id: 0,
                    date: currentTrade.date,
                    symbol: currentTrade.symbol,
                    price: (currentTrade.price * currentTradeAggregationCount + newTrade.price) / (currentTradeAggregationCount + 1),
                    quantity: currentTrade.quantity + newTrade.quantity,
                    buyerIsMaker: true)
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
