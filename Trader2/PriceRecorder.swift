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
    
    private var prices: [PriceRecord] = []
    private let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("prices.json")
    
    let api : TradingPlatform
    
    private var filePath: String {
        return fileUrl.absoluteURL.path
    }
    
    init(api: TradingPlatform) {
        self.api = api
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
