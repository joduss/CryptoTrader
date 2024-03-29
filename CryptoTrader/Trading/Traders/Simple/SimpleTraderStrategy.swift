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
    func updateTicker(bid: Double, ask: Double)
    
    @discardableResult
    func summary(shouldPrint: Bool) -> String
    
    var profits: Double { get }
    
    // Net worth
    var balanceValue: Double { get }
    var openOrders: Int { get }
}
