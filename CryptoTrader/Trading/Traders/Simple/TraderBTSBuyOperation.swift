import Foundation

/// 'Buy then Sell' operation consisting in buying then selling at a higher price.
class TraderBTSBuyOperation {
    
    private(set) var originalBuyOrderQuantity: Double
    private(set) var buyOrder: TradeOrderRequest
    
    private(set) var status: OrderStatus = .new
    
    init(buyOrder: TradeOrderRequest) {
        
        guard buyOrder.side == .buy else {
            fatalError("A buy order for the 'TraderBTSBuyOperation' must have side 'BUY'!")
        }
        
        self.buyOrder = buyOrder
        originalBuyOrderQuantity = buyOrder.quantity
    }
    
    /// Updates the operation with the trade information.
    func update(_ trade: OrderExecutionReport) {
        guard trade.clientOrderId == buyOrder.id else { return }
        
        status = trade.currentOrderStatus
        
        switch trade.currentOrderStatus {
//        case .new:
//            status = .new
//            break
////            return nil
//        case .filled:
//            status = .filled
//            break

//            completed = true
//            return TraderBTSSellOperation(price: trade.price, quantity: trade.lastExecutedQuantity)
        case .partiallyFilled:
            buyOrder.quantity = originalBuyOrderQuantity - trade.cumulativeFilledQuantity
            
            break
//
////            return TraderBTSSellOperation(price: trade.price, quantity: trade.lastExecutedQuantity)
//        case .cancelled:
//            break
////            return nil
//        case .rejected:
//            break
////            return nil
//        case .expired:
////            return nil
//            break
        default: break
        }
    }
    
    func description() -> String {
        return "BTS-Buy - \(buyOrder.id) - \(status) - Price: \(buyOrder.price!) - Qty: \(buyOrder.quantity)"
    }
}
