import Foundation

struct CreatedOrder: CustomStringConvertible {
    
    let symbol: CryptoSymbol
    let platformOrderId: Int
    let clientOrderId: String

    let price: Double
    let originalQty: Double
    let executedQty: Double
    let cummulativeQuoteQty: Double

    let status: OrderStatus
    let type: OrderType
    let side: OrderSide

    let time: Date
    
    var description: String {
        return "CreatedOrder: \(side) \(type) \(originalQty)@\(price)=\(cummulativeQuoteQty)"
    }
}
