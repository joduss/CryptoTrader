//
//  SimulatedTradingPlatform.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation

class SimulatedTradingPlatform: TradingPlatform {
    
    private var prices: [PriceRecord]
    private let startDate: Date
    
    var delegate: TradingPlatformDelegate?
    var simulationSpeed = 60.0
    
    init(prices: [PriceRecord]) {
        self.prices = prices
        self.startDate = prices.first!.time
    }
    
    func listenBtcUsdPrice() {
        
    }
    
    func startSimulation(completed: @escaping () -> ()) {
        print("Simulation started")
        
        for priceRecord in self.prices {
            CurrentDate.instance.date = priceRecord.time
            self.delegate?.priceUpdated(newPrice: priceRecord.price)
        }
        completed()
    }
    
    func pricesInTime(_ time: Date) -> [PriceRecord] {
        var pricesInTimeRange = [PriceRecord]()
        
//        print("Prices until date \(time)")
        
        for price in self.prices {
            if (price.time < time) {
                pricesInTimeRange.append(price)
            }
            else {
                break
            }
        }
        
        if prices.count > 0 {
            self.prices.removeSubrange(0..<pricesInTimeRange.count)
        }
        
        return pricesInTimeRange
    }
    
    
}
