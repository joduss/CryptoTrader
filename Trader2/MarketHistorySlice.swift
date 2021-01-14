//
//  PriceSlice.swift
//  Trader2
//
//  Created by Jonathan Duss on 13.01.21.
//

import Foundation

class MarketHistorySlice {
    
    let prices: ArraySlice<PriceRecord>
    
    private var averagePrice: Double!
    private var min: Double!
    private var max: Double!
    
    init(prices: ArraySlice<PriceRecord>) {
        self.prices = prices
    }
    
    // The interval must be given positive.
    func average() -> Double {
        computeBasic()
        return self.averagePrice
    }

    /// Slope is in price unit per second
    func slope() -> Double {
        var priceDic: [TimeInterval:Double] = [:]
        priceDic.reserveCapacity(prices.count)
        
        for price in prices {
            priceDic[round(price.time.timeIntervalSinceReferenceDate)] = price.price
        }
        
        let firstItemRoundedTimestamp = round(self.prices.first!.time.timeIntervalSinceReferenceDate)
        
        var slope = 0.0
        var last: (TimeInterval, Double) = (TimeInterval(firstItemRoundedTimestamp), priceDic[firstItemRoundedTimestamp]!)
        
        priceDic.removeValue(forKey: firstItemRoundedTimestamp)
        
        for priceTimestamp in priceDic.keys {
            let price = priceDic[priceTimestamp]!
            let localSlope = (price - last.1) - (priceTimestamp - last.0)
            slope += localSlope / Double(priceDic.count)
            
            last = (priceTimestamp, price)
        }
        
        return slope
    }
    
    func variability() -> Variability {
        computeBasic()
                
        return Variability(min: min,
                           max: max,
                           average: averagePrice,
                           spikes07Percent: searchingSpikes(spikeRatioToPrice: 0.7 / 100, priceMin: min, priceMax: max, priceAvg: averagePrice),
                           spikes1Percent:searchingSpikes(spikeRatioToPrice: 1.0 / 100, priceMin: min, priceMax: max, priceAvg: averagePrice))
    }
    
    private func computeBasic() {
        if self.min != nil {
            return
        }
        
        
        var min = Double.greatestFiniteMagnitude
        var max = 0.0
        var total = 0.0
        
        for price in self.prices {
            if (price.price < min) {
                min = price.price
            }
            if (price.price > max) {
                max = price.price
            }
            total += price.price
        }
        
        self.min = min
        self.max = max
        self.averagePrice = total / Double(self.prices.count)
    }
    
    func searchingSpikes(spikeRatioToPrice: Double, priceMin: Double, priceMax: Double, priceAvg: Double) -> UInt {
                
        guard prices.count > 1 else { return 0 }
        
        guard (priceMax - priceMin) / priceAvg > spikeRatioToPrice else {
            return 0
        }
        
        var lastMinBeforeSpike = prices.first!.price
        var lastMaxBeforeSpike = prices.first!.price
        
        var lastSpikePrice: Double?
        var spikeCount: UInt = 0
        
        for priceObject in prices {
            
            let price = priceObject.price
            
            if let lastSpike = lastSpikePrice {
                
                if price > lastMaxBeforeSpike {
                    lastMaxBeforeSpike = price
                } else if (price < lastMinBeforeSpike) {
                    lastMinBeforeSpike = price
                }
                
                let diffPositive = lastMaxBeforeSpike - lastSpike
                let diffNegative = lastMinBeforeSpike - lastSpike

                let diffPositiveToPrice = abs(diffPositive / price)
                let diffNegativeToPrice = abs(diffNegative / price)

                if diffPositiveToPrice >= spikeRatioToPrice || diffNegativeToPrice >= spikeRatioToPrice {
                    lastSpikePrice = price
                    lastMinBeforeSpike = price
                    lastMaxBeforeSpike = price
                    spikeCount += 1
                }
                
            }
            else {
                if price > lastMaxBeforeSpike {
                    lastMaxBeforeSpike = price
                } else if (price < lastMinBeforeSpike) {
                    lastMinBeforeSpike = price
                }
                
                let diff = lastMaxBeforeSpike - lastMinBeforeSpike
                let diffRatioToPrice = diff / price
                
                if diffRatioToPrice >= spikeRatioToPrice {
                    lastSpikePrice = price
                    lastMinBeforeSpike = price
                    lastMaxBeforeSpike = price
                    spikeCount += 1
                }
            }
            
        }
        return spikeCount
    }
}
