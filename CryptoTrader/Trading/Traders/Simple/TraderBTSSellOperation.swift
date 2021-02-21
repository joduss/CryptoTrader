import Foundation


class TraderBTSSellOperation {
    
    var sellOrder: TradeOrderRequest? {
        didSet{
            if let newOrder = sellOrder, newOrder.side != .sell {
                fatalError("A buy order for the 'TraderBTSBuyOperation' must have side 'SELL'!")
            }
        }
    }
    
    private let uuid = UUID().uuidString
    private(set) var status: OrderStatus = .new
    private(set) var trade: TraderBTSTrade
    private(set) var profits = 0.0
    
    /// What was the price when this operation was updated for the last time.
//    var updatedAtPrice: Double

    init(sellOrder: TradeOrderRequest, trade: TraderBTSTrade) {
        guard sellOrder.side == .sell else {
            fatalError("A buy order for the 'TraderBTSBuyOperation' must have side 'SELL'!")
        }
        
        self.trade = trade
        self.sellOrder = sellOrder
    }
    
    init(trade: TraderBTSTrade) {
        self.trade = trade
    }
    
    func update(_ report: OrderExecutionReport) {
        guard report.clientOrderId == sellOrder?.id else { return }
        
        status = report.currentOrderStatus
        
        switch report.currentOrderStatus {
        case .partiallyFilled:
            self.sellOrder?.quantity = trade.quantity - report.cumulativeFilledQuantity
            break
        case .filled:
            profits = report.cumulativeQuoteAssetQuantity - trade.value
            sourcePrint(
                "BTS - Sold \(trade.quantity)@\(report.averagePrice), bought for \(trade.price) " +
                "the \(OutputDateFormatter.format(date: trade.date))). " +
                "Profits: \(profits) (\(Percent(differenceOf: report.cumulativeQuoteAssetQuantity, from: trade.value))%)"
            )
            self.sellOrder?.quantity = 0
        default: break
        }
    }
    
    func description(currentPrice: Double) -> String {
        
        guard self.sellOrder != nil else {
            return "BTS - Sell (Pending) - \(status)- Bought at: \(trade.price) the \(OutputDateFormatter.format(date: trade.date)) - Qty: \(trade.quantity)"
        }
        
        switch status {
        case .new:
            let currentValue = currentPrice * trade.quantity
            let originalValue = trade.value
            let diff = Percent(differenceOf: currentValue, from: originalValue)
            return "BTS operation waiting to be sold. Value: original = \(originalValue), original = \(currentValue) (\(diff)%). Original "
        case .partiallyFilled:
            return "BTS operation partially filled."
        case .filled:
            return "BTS operation completed with profits: \(profits) (\(Percent(ratioOf: profits, to: trade.price))%)"
        case .cancelled:
            return "BTS op cancelled"
        case .rejected:
            return "BTS op rejected"
        case .expired:
            return "BTS op expired"
        }
    }
}
