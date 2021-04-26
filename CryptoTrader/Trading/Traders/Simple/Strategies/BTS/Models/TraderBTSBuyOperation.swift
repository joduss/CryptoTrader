import Foundation

/// 'Buy then Sell' operation consisting in buying then selling at a higher price.
class TraderBTSBuyOperation: CustomStringConvertible {
    
    let uuid: String = UUID().uuidString.truncate(length: 5)
    
    private(set) var stopLossPrice: Decimal = 0
    private(set) var updateWhenBelowPrice: Decimal = Decimal.greatestFiniteMagnitude
    
    private(set) var stopLossPercent: Percent
    private(set) var updateWhenBelowPricePercent: Percent
    
    init(currentPrice: Decimal, stopLossPercent: Percent, updateWhenBelowPricePercent: Percent) {
        self.stopLossPercent = stopLossPercent
        self.updateWhenBelowPricePercent = updateWhenBelowPricePercent
        
        updateStopLoss(newPrice: currentPrice)
    }
    
    init(currentPrice: Decimal, config: TraderBTSStrategyConfig) {
        self.stopLossPercent = config.buyStopLossPercent
        self.updateWhenBelowPricePercent = config.buyUpdateStopLossPercent
        
        updateStopLoss(newPrice: currentPrice)
    }
    
    // MARK: Update base on new price
    
    func updateStopLoss(newPrice: Decimal) {
        guard newPrice < updateWhenBelowPrice else {
            return
        }
        
        stopLossPrice = newPrice +% stopLossPercent
        updateWhenBelowPrice = newPrice -% updateWhenBelowPricePercent
    }
    
    // MARK: Logic
    
    func shouldBuy(at price: Decimal) -> Bool {
        return price >= stopLossPrice
    }
    
    
    // MARK: CustomStringConvertible
    
    var description: String {
        return "BuyOperation \(uuid). Will buy when price > \(stopLossPrice.format(decimals: 3)), update when price < \(updateWhenBelowPrice)"
    }
}
