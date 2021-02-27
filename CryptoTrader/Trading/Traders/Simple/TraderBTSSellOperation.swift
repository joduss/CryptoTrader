import Foundation


class TraderBTSSellOperation: CustomStringConvertible, Codable {
    let uuid: String
    
    let initialTrade: TraderBTSTrade
    
    // If the price goes below the stop-loss-price, a market order is executed.
    var stopLossPrice: Double = 0
    
    // If the price goes over, the stop-loss and update-price are updated.
    var updateWhenAbovePrice: Double = 0
    
    private(set) var status: OrderStatus = .new
    private(set) var profits = 0.0
    private(set) var closingTrade: TraderBTSTrade?
    
    
    init(trade: TraderBTSTrade) {
        uuid = UUID().uuidString.truncate(length: 5)
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
                return
                    "SellOperation \(uuid), Open. "
                    + "Value: original = \(originalValue.format(decimals: 3)), current = \(currentValue.format(decimals: 3)) (\(diff.format(decimals: 3))%). "
                    + "(\(initialTrade.price.format(decimals: 1)) -> \(currentPrice.format(decimals: 1)))"
            case .partiallyFilled:
                return "SellOperation \(uuid), partially filled."
            case .filled:
                let diff = Percent(differenceOf: closingTrade!.value, from: initialTrade.value).percentage
                return "SellOperation \(uuid). Value: original = \(initialTrade.value), current = \(closingTrade!.value) (\(diff)%). (\(initialTrade.price) -> \(currentPrice))"
            case .cancelled:
                return "SellOperation \(uuid) cancelled"
            case .rejected:
                return "SellOperation \(uuid) rejected"
            case .expired:
                return "SellOperation \(uuid) expired"
        }
    }
}
