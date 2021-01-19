//
//  MixedArray.swift
//  Trader2
//
//  Created by Jonathan Duss on 17.01.21.
//

import Foundation


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
                array.append(try arrayContainer.decode(KrakenTicker.self))
            }
            catch {

            }
        }
    }

    init() {}
}
