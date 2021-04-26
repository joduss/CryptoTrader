import Foundation

public struct EMAIndicator {
    
    public let period: Int
    
    /// Array with values ordered in by date increasing.
    public func compute(on data: [Decimal]) -> [Decimal] {
        if (data.count == 0) {
            return []
        }
                
        let smoothingFactor: Decimal = 2.0 / Decimal(period + 1)

        var ema: [Decimal] = [data.first!]
        ema.reserveCapacity(data.count)
        
        
        data.withUnsafeBufferPointer {dataUnsafe in
            for value in dataUnsafe {
                let previousEma = ema.last!
                let newEma = previousEma + smoothingFactor * (value - previousEma)
                ema.append(newEma)
            }
        }
        ema.remove(at: 0)
        
        return ema
    }
}
