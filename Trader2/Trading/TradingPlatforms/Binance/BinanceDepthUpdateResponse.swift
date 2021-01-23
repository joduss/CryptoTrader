//
//  BinanceDepthUpdateResponse.swift
//  Trader2
//
//  Created by Jonathan Duss on 19.01.21.
//

import Foundation

class BinanceDepthUpdateResponse: Decodable {
    
    //{
    //  "e": "depthUpdate", // Event type
    //  "E": 123456789,     // Event time
    //  "s": "BNBBTC",      // Symbol
    //  "U": 157,           // First update ID in event
    //  "u": 160,           // Final update ID in event
    //  "b": [              // Bids to be updated
    //    [
    //      "0.0024",       // Price level to be updated
    //      "10"            // Quantity
    //    ]
    //  ],
    //  "a": [              // Asks to be updated
    //    [
    //      "0.0026",       // Price level to be updated
    //      "100"           // Quantity
    //    ]
    //  ]
    //}
    
    let symbol: String
    private(set) var bidUpdates: [BinanceDepthUpdateElementResponse] = []
    private(set) var askUpdates: [BinanceDepthUpdateElementResponse] = []
    
    enum CodingKeys: String, CodingKey {
        case symbol = "s"
        case askUpdates = "a"
        case bidUpdates = "b"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try values.decode(String.self, forKey: .symbol)
        let bidUpdateArrays = try values.decode([[String]].self, forKey: .bidUpdates)
        
        for bidUpdateArray in bidUpdateArrays {
            bidUpdates.append(BinanceDepthUpdateElementResponse(array: bidUpdateArray))
        }
        
        let askUpdateArrays = try values.decode([[String]].self, forKey: .askUpdates)

        for askUpdateArray in askUpdateArrays {
            askUpdates.append(BinanceDepthUpdateElementResponse(array: askUpdateArray))
        }
    }
}

class BinanceDepthUpdateElementResponse {
    let priceLevel: Double
    let quantity: Double
    
    init(array: [String]) {
        priceLevel = Double(array[0])!
        quantity = Double(array[1])!
    }
}
