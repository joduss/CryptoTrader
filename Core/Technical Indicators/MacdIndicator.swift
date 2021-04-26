import Foundation

/// Oldest to newest
struct Macd {
    var macdLine: [Decimal]
    var signalLine: [Decimal]
}

struct MacdIndicator {
    
    private let shortPeriod: Int
    private let longPeriod: Int
    private let signalPeriod: Int
    
    private let shortPeriodEma: EMAIndicator
    private let longPeriodEma: EMAIndicator
    private let signalPeriodEma: EMAIndicator
    
    private var smoothingFactorShort: Decimal {
        return 2.0 / Decimal(shortPeriod + 1)
    }
    
    private var smoothingFactorLong: Decimal {
        return 2.0 / Decimal(longPeriod + 1)
    }
    
    
    internal init(shortPeriod: Int, longPeriod: Int, signalPeriod: Int) {
        self.shortPeriod = shortPeriod
        self.longPeriod = longPeriod
        self.signalPeriod = signalPeriod
        self.shortPeriodEma = EMAIndicator(period: shortPeriod)
        self.longPeriodEma = EMAIndicator(period: longPeriod)
        self.signalPeriodEma = EMAIndicator(period: signalPeriod)
    }
    
    /// Data: Values from the oldest to the newest
    public func compute(on data: [Decimal]) -> Macd {
        let emaLong = longPeriodEma.compute(on: data)
        let emaShort = shortPeriodEma.compute(on: data)
        
        let diff = MacdIndicator.arraySubstract(a: emaShort, b: emaLong)
        
        let signal = signalPeriodEma.compute(on: diff)
        
        return Macd(macdLine: Array(diff), signalLine: Array(signal))
    }
    
    
    // MARK: - Moving Average
    
    private static func ma(data: [Decimal], period: Int) -> [Decimal] {
        var maValues: [Decimal] = []
        maValues.reserveCapacity(data.count - period + 1)
        
        data.withUnsafeBufferPointer {dataUnsafe in
            var idx = 0
            
            while(idx + period < data.count) {
                let dataPeriod = data[idx...(idx + period)]
                let maValue = MacdIndicator.ma(data: dataPeriod)
                maValues.append(maValue)
                
                idx += 1
            }
        }
        
        return maValues
    }
    
    private static func ma(data: ArraySlice<Decimal>) -> Decimal {
        var average: Decimal = 0.0
        
        data.withUnsafeBufferPointer { dataUnsafe in
            for value in dataUnsafe {
                average += value / Decimal(data.count)
            }
            
        }
        
        return average
    }
    
    /// a - b = c
    private static func arraySubstract(a: [Decimal], b:[Decimal]) -> [Decimal] {
        if (a.count != b.count) {
            fatalError("Both arrays must be of same dimension.")
        }
        
        var result: [Decimal] = []
        result.reserveCapacity(a.count)
        
        var idx = 0
        while (idx < a.endIndex) {
            result.append(a[idx] - b[idx])
            idx += 1
        }
        
        return result
    }
}
