import Foundation

//
//  main.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation

import Cocoa
import os

sourcePrint("Started Trader.")






let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("prices-read3.json")
let data = try Data(contentsOf: fileUrl)
let prices = try JSONDecoder().decode([PriceRecord].self, from: data)


print("Running trader with simulation api.")
let api = SimulatedTradingPlatform(prices: prices)
let trader = Trader(api: api)
api.startSimulation(completed: {
    print("Total profits: \(trader.profits)")
})

//print("Running trader with kraken api.")
//let api = Kraken()
//let trader = PriceRecorder(api: api)

//sourcePrint("Running trader with Binance api.")
//let api = Binance()
//let trader = PriceRecorder(api: api)



RunLoop.main.run()



class Response: Codable {

    let response: String

    var price: Double? = nil

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
        price = (responseArray[1] as! Prices).closePrice
    }
}

struct MixedArray : Decodable {
    var array = [Any]()

    init(from decoder: Decoder) throws {
        var arrayContainer = try decoder.unkeyedContainer()

        while !arrayContainer.isAtEnd {
            do {
                array.append(String(try arrayContainer.decode(String.self)))
            }
            catch {}

            do {
                array.append(String(try arrayContainer.decode(Int.self)))
            }
            catch {

            }

            do {
                array.append(try arrayContainer.decode(Prices.self))
            }
            catch {

            }
        }
    }

    init() {}
}


struct IgnoreAsNil : Decodable {

    init(from decoder: Decoder) throws {}
}

struct Prices: Decodable {

    var c: MixedArray?

    enum CodingKeys: String, CodingKey {
        case c
    }

    var closePrice: Double {
        return Double(c!.array[0] as! String)!
    }
}

