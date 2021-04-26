import Foundation

struct OrderExecutionReport {
    let orderCreationTime: Date
    let symbol: CryptoSymbol
    let clientOrderId: String
    
    let side: OrderSide
    let orderType: OrderType
    let price: Decimal
    
    let currentExecutionType: OrderExecutionType
    let currentOrderStatus: OrderStatus

    let lastExecutedQuantity: Decimal
    let cumulativeFilledQuantity: Decimal
    
    let lastExecutedPrice: Decimal
    let commissionAmount: Decimal
    
    let cumulativeQuoteAssetQuantity: Decimal
    let lastQuoteAssetExecutedQuantity : Decimal

    var averagePrice: Decimal {
        return cumulativeFilledQuantity / cumulativeQuoteAssetQuantity
    }
}
