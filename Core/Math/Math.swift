import Foundation

public struct Math {
    
    public static func average<T: MutableCollection>(data: T) -> Double where T.Element == Double, T.Index == Int  {
        let count = Double(data.count)
        var sum = 0.0
        
        for value in data {
            sum += value
        }
        
        return sum / count
    }
    
}
