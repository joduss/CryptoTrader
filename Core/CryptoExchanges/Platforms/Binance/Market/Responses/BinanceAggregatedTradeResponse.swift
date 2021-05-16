import Foundation


struct BinanceAggregatedTradeResponse: Decodable {
    
    /*{
    "e": "aggTrade",  // Event type
    "E": 123456789,   // Event time
    "s": "BNBBTC",    // Symbol
    "a": 12345,       // Aggregate trade ID
    "p": "0.001",     // Price
    "q": "100",       // Quantity
    "f": 100,         // First trade ID
    "l": 105,         // Last trade ID
    "T": 123456785,   // Trade time
    "m": true,        // Is the buyer the market maker?
    "M": true         // Ignore
    }*/
    
    let date: Int
    let symbol: String
    let tradeId: Int
    let price: Decimal
    let quantity: Decimal
    let buyerIsMarker: Bool
    let ignore: Bool
    
    enum CodingKeys: String, CodingKey {
        case date = "E"
        case symbol = "s"
        case tradeId = "a"
        case price = "p"
        case quantity = "q"
        case buyerIsMarker = "m"
        case ignore = "M"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        date = try values.decode(Int.self, forKey: .date)
        symbol = try values.decode(String.self, forKey: .symbol)
        price = Decimal(try values.decode(String.self, forKey: .price))!
        tradeId = try values.decode(Int.self, forKey: .tradeId)
        quantity = Decimal(try values.decode(String.self, forKey: .quantity))!
        buyerIsMarker = try values.decode(Bool.self, forKey: .buyerIsMarker)
        ignore = try values.decode(Bool.self, forKey: .ignore)
    }
}

