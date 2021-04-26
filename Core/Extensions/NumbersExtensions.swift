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
        return formatter.string(from: self)!
    }
}




