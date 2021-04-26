import Foundation


struct BinanceTickerResponse: Decodable {
    
    //{
    //  "u":400900217,     // order book updateId
    //  "s":"BNBUSDT",     // symbol
    //  "b":"25.35190000", // best bid price
    //  "B":"31.21000000", // best bid qty
    //  "a":"25.36520000", // best ask price
    //  "A":"40.66000000"  // best ask qty
    //}
    
    let updateId: Int
    let symbol: String
    let bidPrice: Decimal
    let bidQuantity: Decimal
    let askPrice: Decimal
    let askQuantity: Decimal

    enum CodingKeys: String, CodingKey {
        case updateId = "u"
        case symbol = "s"
        case bestBidPrice = "b"
        case bestBidQuantity = "B"
        case bestAskPrice = "a"
        case bestAskQuantity = "A"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        updateId = try values.decode(Int.self, forKey: .updateId)
        symbol = try values.decode(String.self, forKey: .symbol)
        bidPrice = Decimal(string: try values.decode(String.self, forKey: .bestBidPrice))!
        bidQuantity = Decimal(string: try values.decode(String.self, forKey: .bestBidQuantity))!
        askPrice = Decimal(string: try values.decode(String.self, forKey: .bestAskPrice))!
        askQuantity = Decimal(string: try values.decode(String.self, forKey: .bestAskQuantity))!
    }
}
