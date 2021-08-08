//
//  KrakenTickerResponse.swift
//  Trader2
//
//  Created by Jonathan Duss on 17.01.21.
//

import Foundation

class KrakenTickerResponse: Codable {

    let response: String

    var price: Double! = nil

    private var responseData: Data {
        return response.data(using: .utf8)!
    }

    init(response: String) {
        self.response = response
        parse()
    }

    private func parse() {
        let decoded = try! JSONDecoder().decode(MixedArray.self, from: responseData)
        let responseArray = decoded.array
//        let dataType = responseArray[2]
        price = (responseArray[1] as! KrakenTicker).closePrice
    }
}
