//
//  PriceRecorder.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation

struct PriceRecord: Codable {
    var time: Date
    var price: Double
}

class PriceRecorder: TradingPlatformDelegate {
    
    private let filePath: String
    private var prices: [PriceRecord] = []
    
    let api : TradingPlatform
    
    
    init(api: TradingPlatform, filePath: String) {
        self.api = api
        self.filePath = filePath
        
        prices.reserveCapacity(100000)
        api.listenBtcUsdPrice()
        self.api.delegate = self
        
        sourcePrint("The price recorder will save prices to \(filePath)")
    }
    
    func priceUpdated(newPrice: Double) {
        sourcePrint("New price: \(newPrice)")
        prices.append(PriceRecord(time: Date(), price: newPrice))
        
        if prices.count % 100 == 0 {
            
            sourcePrint("Saving prices to file...")
            
            let data = try! JSONEncoder().encode(prices)
            if !FileManager.default.fileExists(atPath: filePath) {
                sourcePrint("Creating file at \(filePath)")
                FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            }
            else {
                try! data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            }
        }
    }
}
