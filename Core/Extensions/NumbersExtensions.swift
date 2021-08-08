import Foundation

infix operator £ : AdditionPrecedence

extension Double {
    
    func format(decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: self)!
    }
    
    static func £(value: Double, decimals: Int) -> String {
        return value.format(decimals: decimals)
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
    
    static func £(value: Decimal, decimals: Int) -> String {
        return value.format(decimals: decimals)
    }
}




