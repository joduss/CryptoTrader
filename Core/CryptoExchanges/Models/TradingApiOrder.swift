import Foundation

struct TradingApiOrder {
    let symbol: CryptoSymbol
    let orderId: String
    let platformOrderId: String

    let price: Double
    let originalQty: Double
    let executedQty: Double

    /// Value in the first item of the symbol pair. (qty * price)
    let cumulativeQuotyQty: Double


    let status: OrderStatus
    let type: OrderType
    let side: OrderSide

    let time: Date
    let updateTime: Date

    let originalQuoteQty: Double
}
