//
//  PriceSlice.swift
//  Trader2
//
//  Created by Jonathan Duss on 13.01.21.
//

import Foundation
import JoLibrary

open class MarketHistorySlice {
    
    public internal(set) var prices: ArraySlice<DatedPrice>
    
    private var averagePrice: Double!
    private var min: Double!
    private var max: Double!
    
    public init(prices: ArraySlice<DatedPrice>) {
        self.prices = prices
    }
    
    /// Returns true if there is history in the past in a time interval from now.
//    func hasRecordFromAtLeastPastInterval(_ interval: TimeInterval, now: Date) -> Bool {
//        guard let firstRecord = prices.first else { return false }
//        
//        return firstRecord.date <= DateFactory.now.advanced(by: -interval )
//    }
    
    final public func average() -> Double {
        computeBasic()
        return self.averagePrice
    }
    
    final public func maxPrice() -> Double {
        computeBasic()
        return self.max
    }
    
    final public func minPrice() -> Double {
        computeBasic()
        return self.min
    }

    /// Computes the slope between the beginning of the market history slice and the end, by averaging the first, respectively last
    /// samples withing a range of size 'averageInterval' at the beginning, respectivelly end of the market history slice.
    final func slope() -> Double {
        
        guard let firstTrade = prices.first, let lastTrade = prices.last else {
            return 0
        }
        
        let averageInterval = 4.0
        
        let totalTimeInterval = lastTrade.date - firstTrade.date
        
        let firstPartInterval = self.pricesInInterval(beginDate: firstTrade.date, endDate: firstTrade.date + totalTimeInterval / averageInterval)
        let lastPartInterval = self.pricesInInterval(beginDate: lastTrade.date - totalTimeInterval / averageInterval, endDate: lastTrade.date)

//        for price in prices {
//            priceDic[round(price.date.timeIntervalSinceReferenceDate)] = price.price
//        }
//
//        let firstItemRoundedTimestamp = round(self.prices.first!.date.timeIntervalSinceReferenceDate)
//
//        var slope = 0.0
//        var last: (TimeInterval, Double) = (TimeInterval(firstItemRoundedTimestamp), priceDic[firstItemRoundedTimestamp]!)
//
//        priceDic.removeValue(forKey: firstItemRoundedTimestamp)
//
//        for priceTimestamp in priceDic.keys.sorted() {
//            let price = priceDic[priceTimestamp]!
//            let localSlope = (price - last.1) / (priceTimestamp - last.0)
//            slope += localSlope / Double(priceDic.count)
//
//            last = (priceTimestamp, price)
//        }
//
//        return slope
        
        return (lastPartInterval.average() - firstPartInterval.average()) / Double(totalTimeInterval)
    }
    
//    func isTrendUpwards() -> Bool {
//
//    }
    
    /// Threshold: Percent of change in price to consider a difference of price as a negative trend.
    final func isTrendDownwards(threshold: Percent = 0) -> Bool {
        guard let firstTrade = prices.first, let lastTrade = prices.last else {
            return false
        }
        
        let intervalSlots = 4.0
        
        let totalTimeInterval = lastTrade.date - firstTrade.date
        let intervalSlotDuration = totalTimeInterval / intervalSlots
        
        let firstPartInterval = self.pricesInInterval(beginDate: firstTrade.date, endDate: firstTrade.date + intervalSlotDuration)
        let beforeLastPartInterval = self.pricesInInterval(beginDate: lastTrade.date - 2 * intervalSlotDuration,
                                                           endDate: lastTrade.date - intervalSlotDuration)
        let lastPartInterval = self.pricesInInterval(beginDate: lastTrade.date - intervalSlotDuration, endDate: lastTrade.date)
        
        let lastPartIntervalAvg = lastPartInterval.average()
        let beforeLastPartIntervalAvg = beforeLastPartInterval.average()
        let firstPartIntervalAvg = firstPartInterval.average()
        
//        let durationAToB = totalTimeInterval - 1.5 * intervalSlotDuration
        
//        let slopeAtoB = Percent(Percent(differenceOf: beforeLastPartIntervalAvg, from: firstPartIntervalAvg).percentage / durationAToB)
        let slopeBtoC = Percent(differenceOf: lastPartIntervalAvg, from: beforeLastPartIntervalAvg)
        let slopeAtoC = Percent(differenceOf: lastPartIntervalAvg, from: firstPartIntervalAvg)
        
        if slopeAtoC > threshold {
            return false
        }
        
        if slopeBtoC > threshold {
            return false
        }
        
        return true
    }
    
//    func variability() -> Variability {
//        computeBasic()
//
//        return Variability(min: min,
//                           max: max,
//                           average: averagePrice,
//                           spikes07Percent: searchingSpikes(spikeRatioToPrice: 0.7 / 100, priceMin: min, priceMax: max, priceAvg: averagePrice),
//                           spikes1Percent:searchingSpikes(spikeRatioToPrice: 1.0 / 100, priceMin: min, priceMax: max, priceAvg: averagePrice))
//    }
    
    /// Computes the min, max and average prices.
    private func computeBasic() {
        if self.min != nil {
            return
        }
        
        var min = Double.greatestFiniteMagnitude
        var max: Double = 0.0
        var total: Double = 0.0
        

        if self.prices.count > 2000000 {
            self.prices.withUnsafeBufferPointer({ array in
                for price in array {
                    if (price.price < min) {
                        min = price.price
                    }
                    if (price.price > max) {
                        max = price.price
                    }
                    total += price.price
                }
            })
        }
        else {
            for price in self.prices {
                if (price.price < min) {
                    min = price.price
                }
                if (price.price > max) {
                    max = price.price
                }
                total += price.price
            }
        }
        
        
        self.min = min
        self.max = max
        self.averagePrice = total / Double(self.prices.count)
    }
    
//    func searchingSpikes(spikeRatioToPrice: Double, priceMin: Double, priceMax: Double, priceAvg: Double) -> UInt {
//                
//        guard prices.count > 1 else { return 0 }
//        
//        guard (priceMax - priceMin) / priceAvg > spikeRatioToPrice else {
//            return 0
//        }
//        
//        var lastMinBeforeSpike = prices.first!.price
//        var lastMaxBeforeSpike = prices.first!.price
//        
//        var lastSpikePrice: Double?
//        var spikeCount: UInt = 0
//        
//        
//                
//        for priceObject in prices {
//            
//            let price = priceObject.price
//            
//            if let lastSpike = lastSpikePrice {
//                
//                if price > lastMaxBeforeSpike {
//                    lastMaxBeforeSpike = price
//                } else if (price < lastMinBeforeSpike) {
//                    lastMinBeforeSpike = price
//                }
//                
//                let diffPositive = lastMaxBeforeSpike - lastSpike
//                let diffNegative = lastMinBeforeSpike - lastSpike
//
//                let diffPositiveToPrice = abs(diffPositive / price)
//                let diffNegativeToPrice = abs(diffNegative / price)
//
//                if diffPositiveToPrice >= spikeRatioToPrice || diffNegativeToPrice >= spikeRatioToPrice {
//                    lastSpikePrice = price
//                    lastMinBeforeSpike = price
//                    lastMaxBeforeSpike = price
//                    spikeCount += 1
//                }
//                
//            }
//            else {
//                if price > lastMaxBeforeSpike {
//                    lastMaxBeforeSpike = price
//                } else if (price < lastMinBeforeSpike) {
//                    lastMinBeforeSpike = price
//                }
//                
//                let diff = lastMaxBeforeSpike - lastMinBeforeSpike
//                let diffRatioToPrice = diff / price
//                
//                if diffRatioToPrice >= spikeRatioToPrice {
//                    lastSpikePrice = price
//                    lastMinBeforeSpike = price
//                    lastMaxBeforeSpike = price
//                    spikeCount += 1
//                }
//            }
//            
//        }
//        return spikeCount
//    }
}


// MARK: - History slicing

extension MarketHistorySlice {
    
    /// Returns a market history up to a given point back in the past.
    final func prices(last interval: TimeInterval, before date: Date) -> MarketHistorySlice {
        guard let lastDate = self.prices.last?.date else {
            return MarketHistorySlice(prices: ArraySlice<DatedPrice>())
        }
        
        if date >= lastDate {
            return pricesInInterval(beginDate: (date).advanced(by: -interval))
        }
        else {
            return pricesInInterval(beginDate: (date).advanced(by: -interval), endDate: date)
        }
    }
    
    /// Returns a market history from a given date to the end or to a specific date.
    final func pricesInInterval(beginDate: Date, endDate: Date? = nil) -> MarketHistorySlice {
        
        guard self.prices.count > 0 else {
            return MarketHistorySlice(prices: ArraySlice())
        }
        
        guard let startIdx = findSortedIdx(dateAtLeast: beginDate) else {
            return MarketHistorySlice(prices: ArraySlice<DatedPrice>())

        }

        if let endDate = endDate {
            guard let endIdx = findSortedIdx(dateAtMax: endDate) else {
                return MarketHistorySlice(prices: ArraySlice<DatedPrice>())
            }
            if endIdx <= startIdx { return MarketHistorySlice(prices: ArraySlice<DatedPrice>())}
            
            return MarketHistorySlice(prices: self.prices[startIdx..<endIdx])
        }
        else {
            return MarketHistorySlice(prices: self.prices[startIdx..<self.prices.endIndex])
        }
    }
    
    /// Find the index of the largest date smaller or equal than a given date in a sorted array.
    /// Uses the binary search algorithm.
    final func findSortedIdx(dateAtMax date: Date) -> Int? {
        guard prices.count > 0 else { return nil }
        
        if prices.first!.date > date {
            return nil
        }
        
        if prices.last!.date <= date {
            return prices.endIndex-1
        }
        
        var rangeToSearch = (self.prices.startIndex)...(self.prices.endIndex - 1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range.
            // If the larger element is too large, the smaller might be ok. It still might be larger, so we need to take the one below.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if prices[rangeToSearch.upperBound].date > date {
                    return prices[rangeToSearch.lowerBound].date > date ? rangeToSearch.lowerBound - 1 : rangeToSearch.lowerBound
                }
                return rangeToSearch.upperBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if prices[centerRange].date > date {
                // If the value is larger or equal, we should search smaller values.
                rangeToSearch =  (rangeToSearch.lowerBound)...(centerRange-1)
            }
            else {
                // if the value is smaller, Then we need to search on the right, where larger values are to find the largest value
                // not too big.
                rangeToSearch = (centerRange)...rangeToSearch.upperBound

            }
        }
        
        return rangeToSearch.lowerBound
    }

    /// Find the index of the largest date smaller or equal than a given date in a sorted array.
    /// Uses the binary search algorithm.
    final func findSortedIdx(dateAtLeast date: Date) -> Int? {
        guard prices.count > 0 else { return nil }
        
        if prices.first!.date >= date {
            return prices.startIndex
        }
        
        if prices.last!.date < date {
            return nil
        }
        
        var rangeToSearch = (self.prices.startIndex)...(self.prices.endIndex - 1)
        
        while(rangeToSearch.upperBound != rangeToSearch.lowerBound) {

            // In case there are only 2 elements in the range
            // If the smaller element is too small, we take the larger. It might still be too small. In such case,
            // we take the one above.
            if rangeToSearch.upperBound - 1 == rangeToSearch.lowerBound {
                if prices[rangeToSearch.lowerBound].date < date {
                    return prices[rangeToSearch.upperBound].date >= date ? rangeToSearch.upperBound : rangeToSearch.upperBound + 1
                }
                return rangeToSearch.lowerBound
            }
            
            let centerRange = Int(round(Double((rangeToSearch.upperBound + rangeToSearch.lowerBound)) / 2.0))
            
            if prices[centerRange].date >= date {
                // If the value is larger or equal, we should search smaller values right large enough on the left.
                rangeToSearch =  (rangeToSearch.lowerBound)...centerRange
            }
            else {

                // if the value is smaller, Then we need to search on the right, where larger values are.
                rangeToSearch = (centerRange + 1)...rangeToSearch.upperBound

            }
        }
        
        return rangeToSearch.lowerBound
    }
    
    public func aggregateClose(by interval: TimeInterval, from date: Date) -> MarketHistorySlice {
        guard let last = self.prices.last else { return MarketHistorySlice(prices: ArraySlice())}
        
        var aggregatedPrices = ContiguousArray<DatedPrice>()
        aggregatedPrices.reserveCapacity(self.prices.count)
        
        aggregatedPrices.append(last)
                
        for price in self.prices.reversed() {
            if aggregatedPrices.last!.date - price.date > interval {
                aggregatedPrices.append(price)
            }
        }
        
        aggregatedPrices.reverse()
        
        return MarketHistorySlice(prices: aggregatedPrices[aggregatedPrices.startIndex..<aggregatedPrices.endIndex])
    }
}
