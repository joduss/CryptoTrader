import Foundation

//{
//    "symbol": "BTCUSDT",
//    "orderId": 81831,
//    "orderListId": -1,
//    "clientOrderId": "RZGdaLlzlKTl6NmeZpmDbk",
//    "transactTime": 1614020922430,
//    "price": "0.00000000",
//    "origQty": "0.00420800",
//    "executedQty": "0.00420800",
//    "cummulativeQuoteQty": "99.99080074",
//    "status": "FILLED",
//    "timeInForce": "GTC",
//    "type": "MARKET",
//    "side": "BUY",
//    "fills": [
//        {
//            "price": "20000.00000000",
//            "qty": "0.00373000",
//            "commission": "0.00000000",
//            "commissionAsset": "BTC",
//            "tradeId": 8752
//        },
//        {
//            "price": "53118.83000000",
//            "qty": "0.00047800",
//            "commission": "0.00000000",
//            "commissionAsset": "BTC",
//            "tradeId": 8753
//        }
//    ]
//}
struct BinanceCreateOrderFullResponse: Decodable {

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

    enum CodingKeys: String, CodingKey {
        case symbol
        case platformOrderId = "orderId"
        case clientOrderId = "clientOrderId"
        case price
        case originalQty = "origQty"
        case executedQty = "executedQty"
        case cummulativeQuoteQty
        case stopPrice
        case status
        case type
        case side
        case time = "transactTime"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        symbol = try BinanceSymbolConverter.convert(try values.decode(String.self, forKey: .symbol))
        platformOrderId = try values.decode(Int.self, forKey: .platformOrderId)
        clientOrderId = try values.decode(String.self, forKey: .clientOrderId)

        price = Double(try values.decode(String.self, forKey: .price))!
        originalQty = Double(try values.decode(String.self, forKey: .originalQty))!
        executedQty = Double(try values.decode(String.self, forKey: .executedQty))!
        cummulativeQuoteQty = Double(try values.decode(String.self, forKey: .cummulativeQuoteQty))!

        status = try BinanceOrderStatusConverter.convert(try values.decode(String.self, forKey: .status))
        type = try BinanceOrderTypeConverter.convert(value: try values.decode(String.self, forKey: .type))
        side = try BinanceOrderSideConverter.convert(try values.decode(String.self, forKey: .side))

        time = Date(
            timeIntervalSince1970: TimeInterval.fromMilliseconds(
                try values.decode(TimeInterval.self, forKey: .time)
            )
        )
    }

    init(
        symbol: CryptoSymbol,
        platformOrderId: Int,
        clientOrderId: String,
        price: Double,
        originalQty: Double,
        executedQty: Double,
        cummulativeQuoteQty: Double,
        status: OrderStatus,
        type: OrderType,
        side: OrderSide,
        time: Date
    ) {
        self.symbol = symbol
        self.platformOrderId = platformOrderId
        self.clientOrderId = clientOrderId
        self.price = price
        self.originalQty = originalQty
        self.executedQty = executedQty
        self.cummulativeQuoteQty = cummulativeQuoteQty
        self.status = status
        self.type = type
        self.side = side
        self.time = time
    }

    func toCreatedOrder() -> CreatedOrder {
        
        var orderPriceAvg = self.price
        
        if (type == .market && status == .filled) {
            orderPriceAvg = cummulativeQuoteQty / originalQty
        }
        
        return CreatedOrder(
            symbol: symbol,
            platformOrderId: platformOrderId,
            clientOrderId: clientOrderId,
            price: orderPriceAvg,
            originalQty: originalQty,
            executedQty: executedQty,
            cummulativeQuoteQty: cummulativeQuoteQty,
            status: status,
            type: type,
            side: side,
            time: time
        )
    }
}
