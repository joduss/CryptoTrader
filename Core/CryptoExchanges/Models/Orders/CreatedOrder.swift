import Foundation

struct CreatedOrder: CustomStringConvertible {
    
    let symbol: CryptoSymbol
    let platformOrderId: Int
    let clientOrderId: String

    let price: Decimal
    let originalQty: Decimal
    let executedQty: Decimal
    let cummulativeQuoteQty: Decimal

    let status: OrderStatus
    let type: OrderType
    let side: OrderSide

    let time: Date
    
    var description: String {
        return "CreatedOrder: \(side) \(type) \(originalQty)@\(price)=\(cummulativeQuoteQty)"
    }
}
