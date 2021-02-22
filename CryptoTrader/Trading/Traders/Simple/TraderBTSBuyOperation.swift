import Foundation

/// 'Buy then Sell' operation consisting in buying then selling at a higher price.
class TraderBTSBuyOperation: CustomStringConvertible {
    
    
    let uuid: String = UUID().uuidString.truncate(length: 5)
    var stopLossPrice: Double = 0
    var updateWhenBelowPrice: Double = 0

    private(set) var qty: Double = 0
    private(set) var price: Double = 0
    
    private(set) var status: OrderStatus = .new
    
    var value: Double {
        return qty * price
    }
    
    var description: String {
        return "TODO"
    }

    
    /// Updates the operation with the trade information.
//    func update(_ trade: OrderExecutionReport) {
//        guard trade.clientOrderId == buyOrder.id else { return }
//
//        status = trade.currentOrderStatus
//
//        switch trade.currentOrderStatus {
//        case .partiallyFilled:
//            buyOrder.quantity = originalQty - trade.cumulativeFilledQuantity
//            break
//        default: break
//        }
//    }
//
//    func update(order: TradeOrderRequest) {
//        self.buyOrder = order
//    }
//
//    func description() -> String {
//        return "BTS-Buy - \(buyOrder.id) - \(status) - Price: \(buyOrder.price!) - Qty: \(buyOrder.quantity)"
//    }
}
