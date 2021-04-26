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
    func updateTicker(bid: Decimal, ask: Decimal)
    
    @discardableResult
    func summary(shouldPrint: Bool) -> String
}
