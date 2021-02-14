import Foundation

struct BinanceOpenOrderResponse: Decodable {
    let symbol: CryptoSymbol
    let platformOrderId: Int
    let clientOrderId: String

    let price: Double
    let originalQty: Double
    let executedQty: Double
    let cummulativeQuoteQty: Double
    let stopPrice: Double

    let status: OrderStatus
    let type: OrderType
    let side: OrderSide

    let time: Date
    let updateTime: Date

    let originalQuoteQty: Double
    
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
        
        price = Double(try values.decode(String.self, forKey: .price))!
        originalQty = Double(try values.decode(String.self, forKey: .originalQty))!
        executedQty = Double(try values.decode(String.self, forKey: .executedQty))!
        cummulativeQuoteQty = Double(try values.decode(String.self, forKey: .cummulativeQuoteQty))!
        stopPrice = Double(try values.decode(String.self, forKey: .stopPrice))!
        
        status = try BinanceOrderStatusConverter.convert(try values.decode(String.self, forKey: .status))
        type = try BinanceOrderTypeConverter.convert(value: try values.decode(String.self, forKey: .type))
        side = try BinanceOrderSideConverter.convert(try values.decode(String.self, forKey: .side))

        time = Date(
            timeIntervalSince1970:TimeInterval.fromMilliseconds(try values.decode(TimeInterval.self, forKey: .time))
        )
        updateTime = Date(
            timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(TimeInterval.self, forKey: .updateTime))
        )
        
        originalQuoteQty = Double(try values.decode(String.self, forKey: .originalQuoteQty))!
    }
}
