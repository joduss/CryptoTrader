import Foundation

struct BinanceOrderSummaryResponse: Decodable {
    
    let symbol: CryptoSymbol
    let platformOrderId: Int
    let clientOrderId: String

    let price: Decimal
    let originalQty: Decimal
    let executedQty: Decimal
    let cummulativeQuoteQty: Decimal
    let stopPrice: Decimal

    let status: OrderStatus
    let type: OrderType
    let side: OrderSide

    let time: Date
    let updateTime: Date

    let originalQuoteQty: Decimal
    
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
        case time
        case updateTime
        case originalQuoteQty = "origQuoteOrderQty"
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
        stopPrice = Decimal(string: try values.decode(String.self, forKey: .stopPrice))!
        
        status = try BinanceOrderStatusConverter.convert(try values.decode(String.self, forKey: .status))
        type = try BinanceOrderTypeConverter.convert(value: try values.decode(String.self, forKey: .type))
        side = try BinanceOrderSideConverter.convert(try values.decode(String.self, forKey: .side))

        time = Date(
            timeIntervalSince1970:TimeInterval.fromMilliseconds(try values.decode(TimeInterval.self, forKey: .time))
        )
        updateTime = Date(
            timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(TimeInterval.self, forKey: .updateTime))
        )
        
        originalQuoteQty = Decimal(string: try values.decode(String.self, forKey: .originalQuoteQty))!
    }
    
    init(symbol: CryptoSymbol, platformOrderId: Int, clientOrderId: String, price: Decimal, originalQty: Decimal, executedQty: Decimal, cummulativeQuoteQty: Decimal, stopPrice: Decimal, status: OrderStatus, type: OrderType, side: OrderSide, time: Date, updateTime: Date, originalQuoteQty: Decimal) {
        self.symbol = symbol
        self.platformOrderId = platformOrderId
        self.clientOrderId = clientOrderId
        self.price = price
        self.originalQty = originalQty
        self.executedQty = executedQty
        self.cummulativeQuoteQty = cummulativeQuoteQty
        self.stopPrice = stopPrice
        self.status = status
        self.type = type
        self.side = side
        self.time = time
        self.updateTime = updateTime
        self.originalQuoteQty = originalQuoteQty
    }
}
