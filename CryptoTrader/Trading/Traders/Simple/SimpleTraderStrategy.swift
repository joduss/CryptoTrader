import Foundation

struct ExchangeOrderUpdate {
    let id: String
    let state: OrderStatus
}

protocol SimpleTraderStrategy {
    
    func buyNow()
    
    /// Put sell orders with a given profit in percent.
    func sellAll(profit: Percent)

    func update(report: OrderExecutionReport)
    func updateAsk(price: Double)
    func updateBid(price: Double)
    
    @discardableResult
    func summary(shouldPrint: Bool) -> String
}
