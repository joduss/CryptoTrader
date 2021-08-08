import Foundation

struct OrderExecutionReport {
    let orderCreationTime: Date
    let symbol: CryptoSymbol
    let clientOrderId: String
    
    let side: OrderSide
    let orderType: OrderType
    let price: Double
    
    let currentExecutionType: OrderExecutionType
    let currentOrderStatus: OrderStatus

    let lastExecutedQuantity: Double
    let cumulativeFilledQuantity: Double
    
    let lastExecutedPrice: Double
    let commissionAmount: Double
    
    let cumulativeQuoteAssetQuantity: Double
    let lastQuoteAssetExecutedQuantity : Double

    var averagePrice: Double {
        return cumulativeFilledQuantity / cumulativeQuoteAssetQuantity
    }
}
