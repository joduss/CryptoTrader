import Foundation

public extension Array where Element == Double {
    
    func average() -> Double {
        return self.reduce(0, { (sum, value) in sum + value}) / Double(count)
    }
    
}
