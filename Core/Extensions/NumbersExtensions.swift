import Foundation

extension Double {
    
    func format(decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: self)!
    }
}


extension Decimal {
    func format(decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: self as NSDecimalNumber)!
    }
    
    var doubleValue: Double {
        return (self as NSDecimalNumber).doubleValue
    }
    
    init?(_ string: String) {
        self.init(string: string)
    }
}




