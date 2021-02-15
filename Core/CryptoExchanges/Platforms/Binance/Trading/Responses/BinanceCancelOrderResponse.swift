import Foundation


//{
//  "symbol": "BTCUSDT",
//  "orderId": 28,
//  "orderListId": -1, //Unless OCO, value will be -1
//  "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
//  "transactTime": 1507725176595,
//  "price": "0.00000000",
//  "origQty": "10.00000000",
//  "executedQty": "10.00000000",
//  "cummulativeQuoteQty": "10.00000000",
//  "status": "FILLED",
//  "timeInForce": "GTC",
//  "type": "MARKET",
//  "side": "SELL"
//}
struct BinanceCancelOrderResponse: Decodable {
    
    let symbol: CryptoSymbol
    let platformOrderId: Int
    let clientOrderId: String
    let updateTime: Date
    let time: Date

    enum CodingKeys: String, CodingKey {
        case symbol
        case platformOrderId = "orderId"
        case clientOrderId = "clientOrderId"
        case updateTime
        case time
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        symbol = try BinanceSymbolConverter.convert(try values.decode(String.self, forKey: .symbol))
        platformOrderId = try values.decode(Int.self, forKey: .platformOrderId)
        clientOrderId = try values.decode(String.self, forKey: .clientOrderId)
        updateTime = Date(
            timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(Int.self, forKey: .updateTime))
        )
        time = Date(
            timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(Int.self, forKey: .time))
        )
    }
}
