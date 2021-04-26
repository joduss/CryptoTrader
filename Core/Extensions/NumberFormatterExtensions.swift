import Foundation

extension NumberFormatter {
    
    /// Formats a Double to string.
    public func string(from value: Decimal) -> String? {
        return string(from: value as NSDecimalNumber)
    }
}
