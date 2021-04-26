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
/// Fee is included.
struct BinanceCreateOrderFullResponse: Decodable {

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

        price = Decimal(string: try values.decode(String.self, forKey: .price))!
        originalQty = Decimal(string: try values.decode(String.self, forKey: .originalQty))!
        executedQty = Decimal(string: try values.decode(String.self, forKey: .executedQty))!
        cummulativeQuoteQty = Decimal(string: try values.decode(String.self, forKey: .cummulativeQuoteQty))!

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
        price: Decimal,
        originalQty: Decimal,
        executedQty: Decimal,
        cummulativeQuoteQty: Decimal,
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
        
        if side == .buy {
            return CreatedOrder(
                symbol: symbol,
                platformOrderId: platformOrderId,
                clientOrderId: clientOrderId,
                price: orderPriceAvg,
                originalQty: originalQty,
                executedQty: executedQty,
                cummulativeQuoteQty: cummulativeQuoteQty +% 0.1, // Fee
                status: status,
                type: type,
                side: side,
                time: time
            )
        }
        else {
            return CreatedOrder(
                symbol: symbol,
                platformOrderId: platformOrderId,
                clientOrderId: clientOrderId,
                price: orderPriceAvg,
                originalQty: originalQty,
                executedQty: executedQty,
                cummulativeQuoteQty: cummulativeQuoteQty -% Percent(0.1), // Fee
                status: status,
                type: type,
                side: side,
                time: time
            )
        }
    }
}
