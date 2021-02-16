import Foundation

struct ExchangeOrderUpdate {
    let id: String
    let state: OrderStatus
}

protocol SimpleTraderStrategy {
    
    func update(report: OrderExecutionReport)
    func updateAsk(price: Double)
    func updateBid(price: Double)
}
