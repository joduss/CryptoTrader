import Foundation


//{
//  "symbol": "BTCUSDT",
//  "orderId": 28,
//  "orderListId": -1, //Unless OCO, value will be -1
//  "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
//  "transactTime": 1507725176595
//}

struct BinanceCreateOrderAckResponse: Decodable {
    
    let symbol: CryptoSymbol
    let platformOrderId: Int
    let clientOrderId: String
    let transactionTime: Date
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case platformOrderId = "orderId"
        case clientOrderId = "clientOrderId"
        case transactionTime = "transactTime"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        symbol = try BinanceSymbolConverter.convert(try values.decode(String.self, forKey: .symbol))
        platformOrderId = try values.decode(Int.self, forKey: .platformOrderId)
        clientOrderId = try values.decode(String.self, forKey: .clientOrderId)
        transactionTime = Date(
            timeIntervalSince1970: TimeInterval.fromMilliseconds(try values.decode(Int.self, forKey: .transactionTime))
        )
    }
}
