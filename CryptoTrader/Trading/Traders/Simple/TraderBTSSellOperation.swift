import Foundation


class TraderBTSSellOperation: CustomStringConvertible {
    
    let uuid = UUID().uuidString.truncate(length: 5)
    
    // If the price goes below the stop-loss-price, a market order is executed.
    var stopLossPrice: Double = 0
    
    // If the price goes over, the stop-loss and update-price are updated.
    var updateWhenAbovePrice: Double = 0

    private(set) var status: OrderStatus = .new
    let initialTrade: TraderBTSTrade
    private(set) var profits = 0.0
    private(set) var closingTrade: TraderBTSTrade?

    init(trade: TraderBTSTrade) {
        self.initialTrade = trade
    }
    
    func closing(with order: TraderBTSTrade) {
        status = .filled
        closingTrade = order
        
        profits = order.value - initialTrade.value
    }
    
    var description: String {
        return description(currentPrice: closingTrade?.price ?? initialTrade.price)
    }
    
    
    func description(currentPrice: Double) -> String {
        
        switch status {
        case .new:
            let currentValue = currentPrice * initialTrade.quantity
            let originalValue = initialTrade.value
            let diff = Percent(differenceOf: currentValue, from: originalValue).percentage
            return "Open BTS Sell Operation. Value: original = \(originalValue), current = \(currentValue) (\(diff)%). (\(initialTrade.price) => \(currentPrice) "
        case .partiallyFilled:
            return "BTS Sell Operation partially filled."
        case .filled:
            let diff = Percent(differenceOf: closingTrade!.value, from: initialTrade.value).percentage
            return "Closed BTS Sell Operation. Value: original = \(initialTrade.value), current = \(closingTrade!.value) (\(diff)%). (\(initialTrade.price) => \(currentPrice) "
        case .cancelled:
            return "BTS Sell Operation cancelled"
        case .rejected:
            return "BTS Sell Operation rejected"
        case .expired:
            return "BTS Sell Operation expired"
        }
    }
}
