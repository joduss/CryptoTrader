//
//  Prices.swift
//  Trader2
//
//  Created by Jonathan Duss on 19.01.21.
//

import Foundation


struct KrakenTicker: Decodable {

    var c: MixedArray?

    enum CodingKeys: String, CodingKey {
        case c
    }

    var closePrice: Double {
        return Double(c!.array[0] as! String)!
    }
}
