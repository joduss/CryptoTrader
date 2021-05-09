import Foundation


class TraderBTSSellOperation: CustomStringConvertible, Codable {
    let uuid: String
    let openDate: Date?
    var closeDate: Date?
    
    let initialTrade: TraderBTSTrade
    
    // If the price goes below the stop-loss-price, a market order is executed.
    var stopLossPrice: Decimal = 0
    
    // If the price goes over, the stop-loss and update-price are updated.
    var updateWhenAbovePrice: Decimal = 0
    
    private(set) var status: OrderStatus = .new
    private(set) var profits: Decimal = 0.0
    private(set) var closingTrade: TraderBTSTrade?
    
    
    init(trade: TraderBTSTrade, now: Date) {
        openDate = now
        uuid = UUID().uuidString.truncate(length: 5)
        self.initialTrade = trade
    }
    
    func closing(with order: TraderBTSTrade) {
        status = .filled
        closingTrade = order
        
        profits = order.value - initialTrade.value
        closeDate = order.date
    }
    
    var description: String {
        return description(currentPrice: closingTrade?.price ?? initialTrade.price)
    }
    
    
    func description(currentPrice: Decimal) -> String {
        let df = OutputDateFormatter.instance
        
        let openDateFormatted = openDate != nil ? "\(df.format(date: openDate!))" : "?"
        
        switch status {
            case .new:
                let currentValue = currentPrice * initialTrade.quantity
                let originalValue = initialTrade.value
                let diff = Percent(differenceOf: currentValue, from: originalValue).percentage
                return
                    "Open SellOperation \(uuid) since \(openDateFormatted). "
                    + "Value: original = \(originalValue.format(decimals: 3)), current = \(currentValue.format(decimals: 3)) (\(diff.format(decimals: 3))%). "
                    + "(\(initialTrade.price.format(decimals: 1)) -> \(currentPrice.format(decimals: 1)))"
                    + sellStrategyInfo()
            case .partiallyFilled:
                return "Partial-Filled SellOperation \(uuid) since \(openDateFormatted)."
                
            case .filled:
                let diff = Percent(differenceOf: closingTrade!.value, from: initialTrade.value).percentage.format(decimals: 3)
                let originalValue = initialTrade.value.format(decimals: 3)
                let closeValue = closingTrade!.value.format(decimals: 3)
                let initialPrice = initialTrade.price.format(decimals: 2)
                let closeDateFormatted = closeDate != nil ? "\(df.format(date: closeDate!))" : "?"
                return "Filled SellOperation \(uuid) the \(closeDateFormatted). Value: original = \(originalValue), current = \(closeValue) (\(diff)%). (\(initialPrice) -> \(currentPrice.format(decimals: 2)))"
                
            case .cancelled:
                return "Cancelled SellOperation \(uuid)."
            case .rejected:
                return "Rejected SellOperation \(uuid)."
            case .expired:
                return "Expired SellOperation \(uuid)."
        }
    }
    
    private func sellStrategyInfo() -> String {
        guard stopLossPrice != 0 else {
            return ""
        }
        
        return "\n Will sell if price < \(stopLossPrice.format(decimals: 3)), update if price > \(updateWhenAbovePrice.format(decimals: 3))"
    }
}
