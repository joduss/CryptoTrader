import Foundation

public struct EMAIndicator {
    
    public let period: Int
    
    /// Array with values ordered in by date increasing.
    public func compute(on data: [Double]) -> [Double] {
        if (data.count == 0) {
            return []
        }
                
        let smoothingFactor = 2.0 / Double(period + 1)

        var ema: [Double] = [data.first!]
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
