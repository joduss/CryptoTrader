import Foundation

public struct Math {
    
    public static func average<T: MutableCollection, N: BinaryInteger>(data: T) -> N where T.Element == N, T.Index == Int {
        let count: N = N(data.count)
        var sum: N = N(0.0)
        
        for value in data {
            sum += value
        }
        
        return sum / count
    }
    
    public static func average<T: MutableCollection, N: BinaryFloatingPoint>(data: T) -> N where T.Element == N, T.Index == Int {
        let count: N = N(data.count)
        var sum: N = N(0.0)
        
        for value in data {
            sum += value
        }
        
        return sum / count
    }
    
    public static func average<T: MutableCollection>(data: T) -> Decimal where T.Element == Decimal, T.Index == Int  {
        let count = Decimal(data.count)
        var sum: Decimal = 0.0
        
        for value in data {
            sum += value
        }
        
        return sum / count
    }
    
}
